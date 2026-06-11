#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari adapters/codex/install.sh
rm -rf .palari
rm -f tickets/open/*.md tickets/proposed/*.md tickets/closed/*.md
rm -f reports/*.md reports/planning/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "codex@example.invalid"
git config user.name "Codex Executor Test"

./bin/palari init >/dev/null
mkdir -p docs
git add .
git commit -m "codex executor baseline" >/dev/null

./bin/palari ticket create LAB-0400 "Codex dry run" \
	--stream lab \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "true" >/dev/null
git add tickets/open/LAB-0400-*.md
git commit -m "add codex dry-run ticket" >/dev/null

run_dry_run_without_codex_cli() {
	./bin/palari agent run LAB-0400 \
		--executor codex \
		--model gpt-5-codex \
		--prompt "Dry-run codex contract." \
		--dry-run >"$TMP_ROOT/dry.out"
	grep -Fq "agent run: dry-run for LAB-0400" "$TMP_ROOT/dry.out"
	grep -Fq "executor: codex" "$TMP_ROOT/dry.out"
	grep -Fq "model: gpt-5-codex" "$TMP_ROOT/dry.out"
	grep -Fq "command: codex exec --cd" "$TMP_ROOT/dry.out"
	grep -Fq -- "--sandbox workspace-write" "$TMP_ROOT/dry.out"
	grep -Fq "Read the Palari mission packet at" "$TMP_ROOT/dry.out"
	grep -Fq "Dry-run codex contract." "$TMP_ROOT/dry.out"
	WORKTREE="$(awk -F': ' '/^worktree: \// { print $2; exit }' "$TMP_ROOT/dry.out")"
	EVIDENCE="$(awk -F': ' '/^evidence: / { print $2; exit }' "$TMP_ROOT/dry.out")"
	test -f "$WORKTREE/$EVIDENCE/command.txt"
	test -f "$WORKTREE/reports/LAB-0400-codex-packet.md"
	grep -Fq "codex exec" "$WORKTREE/$EVIDENCE/command.txt"
}

run_real_run_requires_codex_cli() {
	if command -v codex >/dev/null 2>&1; then
		printf 'codex CLI present; skipping missing-CLI check\n'
		return 0
	fi
	./bin/palari ticket create LAB-0401 "Codex real run" \
		--stream lab \
		--risk R1 \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "true" >/dev/null
	git add tickets/open/LAB-0401-*.md
	git commit -m "add codex real-run ticket" >/dev/null
	if ./bin/palari agent run LAB-0401 --executor codex >"$TMP_ROOT/real.out" 2>"$TMP_ROOT/real.err"; then
		echo "real codex run should fail without the codex CLI" >&2
		exit 1
	fi
	grep -Fq "requires codex on PATH" "$TMP_ROOT/real.err"
}

run_scenario_rejected_for_codex() {
	if ./bin/palari agent run LAB-0400 --executor codex --scenario safe --dry-run >"$TMP_ROOT/scen.out" 2>"$TMP_ROOT/scen.err"; then
		echo "--scenario must be mock-only" >&2
		exit 1
	fi
	grep -Fq -- "--scenario is only valid with --executor mock" "$TMP_ROOT/scen.err"
}

run_codex_doctor_reports_readiness() {
	export CODEX_PROMPTS_DIR="$TMP_ROOT/prompts"
	./bin/palari codex doctor >"$TMP_ROOT/doctor-warn.out"
	grep -Fq "codex doctor: ok AGENTS.md present" "$TMP_ROOT/doctor-warn.out"
	grep -Fq "codex doctor: ok bin/palari executable" "$TMP_ROOT/doctor-warn.out"
	grep -Fq "codex doctor: ok palari.config.yaml present" "$TMP_ROOT/doctor-warn.out"
	grep -Fq "codex doctor: warning codex prompts not installed" "$TMP_ROOT/doctor-warn.out"
	grep -Fq "codex doctor: ok executor support" "$TMP_ROOT/doctor-warn.out"
	grep -Fxq "codex doctor: ok" "$TMP_ROOT/doctor-warn.out"

	./bin/palari codex install "$CODEX_PROMPTS_DIR" >"$TMP_ROOT/install.out"
	grep -Fq "palari codex prompts installed" "$TMP_ROOT/install.out"
	./bin/palari codex doctor >"$TMP_ROOT/doctor-ok.out"
	grep -Fq "codex doctor: ok codex prompts installed" "$TMP_ROOT/doctor-ok.out"
	unset CODEX_PROMPTS_DIR
}

run_codex_doctor_fails_without_agents_md() {
	mv AGENTS.md "$TMP_ROOT/AGENTS.md.bak"
	if ./bin/palari codex doctor >"$TMP_ROOT/doctor-fail.out" 2>"$TMP_ROOT/doctor-fail.err"; then
		mv "$TMP_ROOT/AGENTS.md.bak" AGENTS.md
		echo "codex doctor should fail without AGENTS.md" >&2
		exit 1
	fi
	mv "$TMP_ROOT/AGENTS.md.bak" AGENTS.md
	grep -Fq "missing AGENTS.md" "$TMP_ROOT/doctor-fail.out"
	grep -Fq "codex doctor: failed with 1 issue(s)" "$TMP_ROOT/doctor-fail.err"
}

run_dry_run_without_codex_cli
run_real_run_requires_codex_cli
run_scenario_rejected_for_codex
run_codex_doctor_reports_readiness
run_codex_doctor_fails_without_agents_md

printf 'agent-codex: ok\n'
