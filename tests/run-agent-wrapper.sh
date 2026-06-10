#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-agent-wrapper.sh
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "agent-wrapper@example.invalid"
git config user.name "Agent Wrapper Test"

./bin/palari init >/dev/null
mkdir -p docs
git add .
git commit -m "initial wrapper test" >/dev/null

./bin/palari ticket create LAB-0200 "Sandbox copy" \
	--stream lab \
	--risk R1 \
	--allowed "docs/lab-0200.md" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "test -f docs/lab-0200.md" >/dev/null
git add tickets/open/LAB-0200-*.md
git commit -m "add sandbox ticket" >/dev/null

./bin/palari sandbox create LAB-0200 >"$TMP_ROOT/sandbox.out"
SANDBOX_REPO="$(awk -F': ' '/Sandbox repo:/ { print $2 }' "$TMP_ROOT/sandbox.out")"
test -d "$SANDBOX_REPO/.git"
grep -Fxq "LAB-0200" "$SANDBOX_REPO/.palari-sandbox"
grep -Fxq ".palari/" "$SANDBOX_REPO/.gitignore"
git status --short >"$TMP_ROOT/status-after-sandbox.out"
test ! -s "$TMP_ROOT/status-after-sandbox.out"
(cd "$SANDBOX_REPO" && ./bin/palari status >"$TMP_ROOT/sandbox-status.out")
grep -Fq "Palari Orchestration status" "$TMP_ROOT/sandbox-status.out"

./bin/palari ticket create LAB-0201 "opencode dry run" \
	--stream lab \
	--risk R1 \
	--allowed "docs/lab-0201.md" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "test -f docs/lab-0201.md" >/dev/null
git add tickets/open/LAB-0201-*.md
git commit -m "add opencode dry-run ticket" >/dev/null

./bin/palari agent run LAB-0201 \
	--executor opencode \
	--model opencode/test-model \
	--prompt "Dry-run executor contract." \
	--dry-run >"$TMP_ROOT/agent-dry-run.out"

grep -Fq "agent run: dry-run for LAB-0201" "$TMP_ROOT/agent-dry-run.out"
grep -Fq "executor: opencode" "$TMP_ROOT/agent-dry-run.out"
grep -Fq "denied: palari *, ./bin/palari *, bin/palari *, git commit*, git push*, git merge*, gh pr merge*, rm *" "$TMP_ROOT/agent-dry-run.out"

WORKTREE="$(awk -F': ' '/^worktree: \// { print $2; exit }' "$TMP_ROOT/agent-dry-run.out")"
PACKET="$(awk -F': ' '/packet:/ { print $2; exit }' "$TMP_ROOT/agent-dry-run.out")"
EVIDENCE="$(awk -F': ' '/evidence:/ { print $2; exit }' "$TMP_ROOT/agent-dry-run.out")"
test -d "$WORKTREE"
test -f "$PACKET"
test -f "$WORKTREE/$EVIDENCE/command.txt"
grep -Fq "opencode run" "$WORKTREE/$EVIDENCE/command.txt"
grep -Fq "Dry-run executor contract." "$WORKTREE/$EVIDENCE/command.txt"

if grep -Fq "palari_accept" adapters/mcp/tools.json; then
	printf 'agent-wrapper: MCP manifest must still not expose acceptance\n' >&2
	exit 1
fi

# --- report-lint missing-heading diagnostic ---
./bin/palari ticket create LAB-0202 "Report heading test" \
	--stream lab \
	--risk R2 \
	--allowed "reports/**" \
	--allowed "tickets/**" \
	--verify "true" >/dev/null

TICKET_FILE="$(ls tickets/open/LAB-0202-*.md)"
sed -i 's/^status: .*/status: in-review/' "$TICKET_FILE"

cat >"reports/LAB-0202-technical-report.md" <<'REPORT'
# LAB-0202 Technical Report

## Files Changed

- None

## Verification

- None

## Risks / Follow-Ups

- None
REPORT

if ./bin/palari lint LAB-0202 2>"$TMP_ROOT/lint-heading.err"; then
	printf 'agent-wrapper: missing heading lint should fail\n' >&2
	exit 1
fi
grep -Fq "LAB-0202-technical-report.md" "$TMP_ROOT/lint-heading.err"
grep -Fq "missing" "$TMP_ROOT/lint-heading.err"
grep -Fq "CI Evidence" "$TMP_ROOT/lint-heading.err"
grep -Fq "add this heading" "$TMP_ROOT/lint-heading.err"

# --- evidence manifest validation failure modes ---
export ROOT="$WORK"
export EVIDENCE_DIR="reports/evidence"
source "$REPO_ROOT/lib/palari/ci_accept.bash"

check_diagnostic() {
	local scenario="$1" label="$2" grep_pattern="$3"
	if ! grep -Fq "$grep_pattern" "$TMP_ROOT/$scenario.err"; then
		printf 'agent-wrapper: %s: expected diagnostic containing "%s"\n' "$label" "$grep_pattern" >&2
		printf '  stderr: %s\n' "$(cat "$TMP_ROOT/$scenario.err")" >&2
		exit 1
	fi
}

# 1. broken JSON
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf 'not json\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/broken-json.err" && {
	printf 'expected broken JSON to fail\n' >&2
	exit 1
}
check_diagnostic "broken-json" "broken JSON" "cannot parse"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 2. wrong schema_version
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"0","generator":"palari-ci","ticket":"BADMAN-001","status":"passed","artifacts":[]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/wrong-schema.err" && {
	printf 'expected wrong schema to fail\n' >&2
	exit 1
}
check_diagnostic "wrong-schema" "wrong schema" "schema_version"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 3. wrong generator
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"1","generator":"not-palari","ticket":"BADMAN-001","status":"passed","artifacts":[]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/wrong-generator.err" && {
	printf 'expected wrong generator to fail\n' >&2
	exit 1
}
check_diagnostic "wrong-generator" "wrong generator" "generator"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 4. wrong status
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"1","generator":"palari-ci","ticket":"BADMAN-001","status":"failed","artifacts":[]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/wrong-status.err" && {
	printf 'expected wrong status to fail\n' >&2
	exit 1
}
check_diagnostic "wrong-status" "wrong status" "status"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 5. missing artifacts list
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"1","generator":"palari-ci","ticket":"BADMAN-001","status":"passed"}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/missing-artifacts.err" && {
	printf 'expected missing artifacts to fail\n' >&2
	exit 1
}
check_diagnostic "missing-artifacts" "missing artifacts" "artifacts"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 6. invalid sha256 length
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"1","generator":"palari-ci","ticket":"BADMAN-001","status":"passed","artifacts":[{"name":"verification.log","sha256":"short"}]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/bad-sha256.err" && {
	printf 'expected bad sha256 to fail\n' >&2
	exit 1
}
check_diagnostic "bad-sha256" "bad sha256" "sha256"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 7. artifact file missing
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf '{"schema_version":"1","generator":"palari-ci","ticket":"BADMAN-001","status":"passed","artifacts":[{"name":"verification.log","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/missing-file.err" && {
	printf 'expected missing file to fail\n' >&2
	exit 1
}
check_diagnostic "missing-file" "missing file" "missing or empty"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

# 8. sha256 checksum mismatch
mkdir -p "$WORK/$EVIDENCE_DIR/BADMAN-001"
printf 'some content\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/verification.log"
printf '{"schema_version":"1","generator":"palari-ci","ticket":"BADMAN-001","status":"passed","artifacts":[{"name":"verification.log","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]}\n' >"$WORK/$EVIDENCE_DIR/BADMAN-001/manifest.json"
ci_existing_evidence_valid "BADMAN-001" 2>"$TMP_ROOT/sha256-mismatch.err" && {
	printf 'expected sha256 mismatch to fail\n' >&2
	exit 1
}
check_diagnostic "sha256-mismatch" "sha256 mismatch" "sha256 mismatch"
rm -rf "$WORK/$EVIDENCE_DIR/BADMAN-001"

printf 'agent-wrapper: ok\n'
