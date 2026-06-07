#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-memory.sh
rm -rf .palari memory
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "memory@example.invalid"
git config user.name "Memory Test"

./bin/palari init >/dev/null
./bin/palari memory lint >"$TMP_ROOT/no-memory-lint.out"
grep -Fq "memory-lint: ok (no memory directory)" "$TMP_ROOT/no-memory-lint.out"

./bin/palari ticket create APP-0001 "Memory packet smoke" \
	--stream web \
	--risk R1 \
	--allowed "adapters/web/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--allowed "memory/**" \
	--verify "memory packet check" >/dev/null

git add .
git commit -m "memory test baseline" >/dev/null

./bin/palari worktree APP-0001 >"$TMP_ROOT/worktree.out"
./bin/palari packet APP-0001 specialist >"$TMP_ROOT/no-memory.packet"
grep -Fq "Relevant Memory" "$TMP_ROOT/no-memory.packet"
grep -Fq "none selected" "$TMP_ROOT/no-memory.packet"

ADD_OUT="$(./bin/palari memory add invariant "Console stays read-only" \
	--truth-key web.console.mutation_boundary \
	--path "adapters/web/**" \
	--tag web \
	--tag console \
	--tag read-only \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status active \
	--body $'## Current Truth\n\nThe console may render repository state and copyable commands, but must not mutate tickets, reports, evidence, claims, or acceptance state.\n\n## Why\n\nThe repo must remain the source of truth.\n\n## Checks\n\n- palari web --check')"
MEM1="$(printf '%s\n' "$ADD_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"
test -f "memory/invariants/$MEM1-console-stays-read-only.md"

./bin/palari memory lint >"$TMP_ROOT/valid-memory-lint.out"
grep -Fq "memory-lint: ok" "$TMP_ROOT/valid-memory-lint.out"

./bin/palari memory index --sqlite >"$TMP_ROOT/memory-index.out" 2>"$TMP_ROOT/memory-index.err"
test -f .palari/cache/memory-index.json
if [[ ! -f .palari/cache/memory.sqlite ]]; then
	grep -Fq "FTS5 is unavailable" "$TMP_ROOT/memory-index.err"
fi

./bin/palari memory query "read-only console" >"$TMP_ROOT/text-query.out"
grep -Fq "$MEM1" "$TMP_ROOT/text-query.out"
./bin/palari memory query --path adapters/web/server.py >"$TMP_ROOT/path-query.out"
grep -Fq "$MEM1" "$TMP_ROOT/path-query.out"

PROPOSED_OUT="$(./bin/palari memory add gotcha "Proposed hidden warning" \
	--truth-key web.console.proposed_warning \
	--path "adapters/web/**" \
	--tag web \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status proposed \
	--body $'## Current Truth\n\nThis proposed warning should not enter packets yet.')"
PROPOSED="$(printf '%s\n' "$PROPOSED_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"
./bin/palari memory query "Proposed hidden warning" >"$TMP_ROOT/proposed-default-query.out"
if grep -Fq "$PROPOSED" "$TMP_ROOT/proposed-default-query.out"; then
	printf 'memory: proposed memory appeared in default query\n' >&2
	exit 1
fi
./bin/palari memory query "Proposed hidden warning" --include-inactive >"$TMP_ROOT/proposed-inactive-query.out"
grep -Fq "$PROPOSED" "$TMP_ROOT/proposed-inactive-query.out"

OLD_OUT="$(./bin/palari memory add command "Use legacy console command" \
	--truth-key web.console.command \
	--path "adapters/web/**" \
	--tag web \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status active \
	--body $'## Current Truth\n\nUse the old console command.')"
OLD="$(printf '%s\n' "$OLD_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"
./bin/palari memory supersede "$OLD" \
	--title "Use current console command" \
	--source-ticket APP-0001 \
	--body $'## Current Truth\n\nUse the current console command.' >"$TMP_ROOT/supersede.out"
NEW="$(sed -E 's/.*(MEM-[0-9]+) -> (MEM-[0-9]+).*/\2/' "$TMP_ROOT/supersede.out" | tail -n 1)"
./bin/palari memory query --truth-key web.console.command >"$TMP_ROOT/superseded-query.out"
grep -Fq "$NEW" "$TMP_ROOT/superseded-query.out"
if grep -Fq "$OLD " "$TMP_ROOT/superseded-query.out"; then
	printf 'memory: superseded memory appeared in default query\n' >&2
	exit 1
fi

DUP_OUT="$(./bin/palari memory add invariant "Console narrow exception" \
	--truth-key web.console.mutation_boundary \
	--path "adapters/web/static/**" \
	--tag web \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status active \
	--body $'## Current Truth\n\nStatic console assets may use build-time constants, but must not add mutation endpoints.')"
DUP="$(printf '%s\n' "$DUP_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"
if ./bin/palari memory lint >"$TMP_ROOT/duplicate-lint.out" 2>&1; then
	printf 'memory: expected duplicate active truth lint to fail\n' >&2
	exit 1
fi
grep -Fq "active truth_key web.console.mutation_boundary overlaps" "$TMP_ROOT/duplicate-lint.out"
python3 - <<PY
from pathlib import Path
path = next(Path("memory").rglob("$DUP-*.md"))
text = path.read_text(encoding="utf-8")
text = text.replace("  exception_of:\n", "  exception_of:\n    - $MEM1\n")
path.write_text(text, encoding="utf-8")
PY
./bin/palari memory lint >"$TMP_ROOT/exception-lint.out"
grep -Fq "memory-lint: ok" "$TMP_ROOT/exception-lint.out"

REJECTED_OUT="$(./bin/palari memory add failure "Rejected console rumor" \
	--truth-key web.console.rejected \
	--path "adapters/web/**" \
	--tag web \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status rejected \
	--body $'## Current Truth\n\nRejected memories must not enter packets.')"
REJECTED="$(printf '%s\n' "$REJECTED_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"

./bin/palari packet APP-0001 specialist >"$TMP_ROOT/specialist.packet"
grep -Fq "Relevant Memory" "$TMP_ROOT/specialist.packet"
grep -Fq "$MEM1" "$TMP_ROOT/specialist.packet"
grep -Fq "Console stays read-only" "$TMP_ROOT/specialist.packet"
if grep -Fq "$PROPOSED" "$TMP_ROOT/specialist.packet" ||
	grep -Fq "$OLD" "$TMP_ROOT/specialist.packet" ||
	grep -Fq "$REJECTED" "$TMP_ROOT/specialist.packet"; then
	printf 'memory: packet included inactive memory\n' >&2
	exit 1
fi

./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
python3 - "$TMP_ROOT/snapshot.json" <<'PY'
import json
import sys
from pathlib import Path

snapshot = json.loads(Path(sys.argv[1]).read_text())
assert "memory" in snapshot
assert snapshot["memory"]["active"] >= 2
assert snapshot["memory"]["proposed"] >= 1
PY

./bin/palari memory graph "$NEW" >"$TMP_ROOT/graph.out"
grep -Fq "supersedes: $OLD" "$TMP_ROOT/graph.out"

PROMOTE_OUT="$(./bin/palari memory add pattern "Console refresh pattern" \
	--truth-key web.console.refresh_pattern \
	--path "adapters/web/**" \
	--tag web \
	--source-ticket APP-0001 \
	--evidence tests/run-memory.sh \
	--status proposed \
	--body $'## Current Truth\n\nRefresh flows should preserve the snapshot contract.')"
PROMOTE_ID="$(printf '%s\n' "$PROMOTE_OUT" | sed -E 's/.*(MEM-[0-9]+).*/\1/')"
./bin/palari memory promote "$PROMOTE_ID" --by reviewer >"$TMP_ROOT/promote.out"
./bin/palari memory query --truth-key web.console.refresh_pattern >"$TMP_ROOT/promoted-query.out"
grep -Fq "$PROMOTE_ID active pattern" "$TMP_ROOT/promoted-query.out"

printf 'memory: ok\n'
