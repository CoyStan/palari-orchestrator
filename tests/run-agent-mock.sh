#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari
rm -rf .palari
rm -f tickets/open/*.md tickets/proposed/*.md tickets/closed/*.md
rm -f reports/*.md reports/planning/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "mock@example.invalid"
git config user.name "Mock Executor Test"

./bin/palari init >/dev/null
mkdir -p docs
printf '# docs\n' >docs/index.md
git add .
git commit -m "mock executor baseline" >/dev/null

new_mock_ticket() {
	local id="$1"
	./bin/palari ticket create "$id" "Mock run $id" \
		--stream lab \
		--risk R1 \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "true" >/dev/null
	git add "tickets/open/$id-"*.md
	git commit -m "add $id" >/dev/null
}

run_dry_run_without_ai_tool() {
	new_mock_ticket LAB-0300
	./bin/palari agent run LAB-0300 --executor mock --scenario safe --dry-run >"$TMP_ROOT/dry.out"
	grep -Fq "agent run: dry-run for LAB-0300" "$TMP_ROOT/dry.out"
	grep -Fq "executor: mock" "$TMP_ROOT/dry.out"
	grep -Fq "scenario: safe" "$TMP_ROOT/dry.out"
	grep -Fq "no AI tool, network, or credentials involved" "$TMP_ROOT/dry.out"
}

run_safe_scenario_passes_gates() {
	new_mock_ticket LAB-0303
	./bin/palari agent run LAB-0303 --executor mock --scenario safe >"$TMP_ROOT/safe.out"
	grep -Fq "agent run: LAB-0303 via mock" "$TMP_ROOT/safe.out"
	grep -Fq "mock exit: 0" "$TMP_ROOT/safe.out"
	grep -Fq "scope-check exit: 0" "$TMP_ROOT/safe.out"
	grep -Fq "ci exit: 0" "$TMP_ROOT/safe.out"
	WORKTREE="$(awk -F': ' '/^Ticket worktree: / { print $2; exit }' "$TMP_ROOT/safe.out")"
	test -f "$WORKTREE/docs/mock-executor.md"
	test -f "$WORKTREE/reports/evidence/LAB-0303/executor/mock/run.stdout"
	test -f "$WORKTREE/reports/evidence/LAB-0303/executor/mock/command.txt"
	grep -Fxq "0" "$WORKTREE/reports/evidence/LAB-0303/executor/mock/run.exit"
}

run_forbidden_path_is_refused() {
	new_mock_ticket LAB-0301
	if ./bin/palari agent run LAB-0301 --executor mock --scenario forbidden-path >"$TMP_ROOT/forbidden.out" 2>&1; then
		echo "forbidden-path scenario should fail gates" >&2
		exit 1
	fi
	grep -Fq "mock exit: 0" "$TMP_ROOT/forbidden.out"
	grep -Fq "scope-check exit: 1" "$TMP_ROOT/forbidden.out"
	grep -Fq "scope-check: refused the change; evidence preserved, ticket state not advanced" "$TMP_ROOT/forbidden.out"
	WORKTREE="$(awk -F': ' '/^Ticket worktree: / { print $2; exit }' "$TMP_ROOT/forbidden.out")"
	EVIDENCE="$WORKTREE/reports/evidence/LAB-0301/executor/mock"
	grep -Fq ".env forbidden by ticket LAB-0301" "$EVIDENCE/scope-check.err"
	test -f "$EVIDENCE/run.stdout"
	# Ticket state must not have advanced.
	if grep -Fq "status: claimed" tickets/open/LAB-0301-*.md; then
		echo "refused run must not advance ticket state" >&2
		exit 1
	fi
	grep -Fq "status: open" tickets/open/LAB-0301-*.md
}

run_outside_scope_is_refused() {
	new_mock_ticket LAB-0302
	if ./bin/palari agent run LAB-0302 --executor mock --scenario outside-scope >"$TMP_ROOT/outside.out" 2>&1; then
		echo "outside-scope scenario should fail gates" >&2
		exit 1
	fi
	grep -Fq "scope-check exit: 1" "$TMP_ROOT/outside.out"
	WORKTREE="$(awk -F': ' '/^Ticket worktree: / { print $2; exit }' "$TMP_ROOT/outside.out")"
	grep -Fq 'path "mock-executor-outside.txt" is outside allowed_paths' \
		"$WORKTREE/reports/evidence/LAB-0302/executor/mock/scope-check.err"
}

run_scenario_rejected_for_opencode() {
	if ./bin/palari agent run LAB-0300 --executor opencode --scenario safe --dry-run >"$TMP_ROOT/wrong.out" 2>"$TMP_ROOT/wrong.err"; then
		echo "--scenario must be mock-only" >&2
		exit 1
	fi
	grep -Fq -- "--scenario is only valid with --executor mock" "$TMP_ROOT/wrong.err"
}

run_unknown_scenario_rejected() {
	if ./bin/palari agent run LAB-0300 --executor mock --scenario chaos >"$TMP_ROOT/chaos.out" 2>"$TMP_ROOT/chaos.err"; then
		echo "unknown scenario should be rejected" >&2
		exit 1
	fi
	grep -Fq "unknown mock scenario: chaos" "$TMP_ROOT/chaos.err"
}

run_dry_run_without_ai_tool
run_safe_scenario_passes_gates
run_forbidden_path_is_refused
run_outside_scope_is_refused
run_scenario_rejected_for_opencode
run_unknown_scenario_rejected

printf 'agent-mock: ok\n'
