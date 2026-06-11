#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'queue-dry-run: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* goals decisions
mkdir -p goals/active decisions/open decisions/decided

git init -b main >/dev/null
git config user.email "run@example.invalid"
git config user.name "Run Test"
git add .
git commit -m "run baseline" >/dev/null

# Fail closed without --dry-run.
if ./bin/palari run >/dev/null 2>&1; then
	fail "palari run without --dry-run must fail closed"
fi

# Empty queue plans nothing and changes nothing.
./bin/palari run --dry-run >"$TMP_ROOT/empty.out"
grep -Fq "planned: 0" "$TMP_ROOT/empty.out" || fail "empty queue should plan 0 steps"

# A goal, a plannable ticket, a needs-human ticket, and an open decision.
./bin/palari goal create GOAL-0001 "Demo goal" --success "Done" >/dev/null
./bin/palari ticket create QRD-0001 "Plannable work" --goal GOAL-0001 \
	--allowed "README.md" --verify "test -f README.md" >/dev/null
./bin/palari ticket create QRD-0002 "Parked work" \
	--allowed "CHANGELOG.md" --verify "true" >/dev/null
./bin/palari ticket needs-human QRD-0002 >/dev/null
./bin/palari decide create DEC-0001 "Direction question" \
	--option "Path A" --option "Path B" --recommend 1 >/dev/null

git_state_before="$(git status --porcelain | sort)"
./bin/palari run --dry-run >"$TMP_ROOT/plan.out"
git_state_after="$(git status --porcelain | sort)"
[[ "$git_state_before" == "$git_state_after" ]] ||
	fail "dry-run mutated repository state"

# Stop items: the open decision and the needs-human ticket.
grep -Eq '^stop +DEC-0001' "$TMP_ROOT/plan.out" ||
	fail "open decision should surface as a stop item"
grep -Eq '^stop +QRD-0002' "$TMP_ROOT/plan.out" ||
	fail "needs-human ticket should surface as a stop item"
# The decision is the first plan line.
first_item="$(grep -E '^(stop|next|skip) ' "$TMP_ROOT/plan.out" | head -1)"
printf '%s' "$first_item" | grep -Fq "DEC-0001" ||
	fail "open decisions should surface before ticket work"

# Plannable work appears with a role lens and a copyable command.
grep -Eq '^next +QRD-0001' "$TMP_ROOT/plan.out" || fail "plannable ticket missing"
grep -Fq "role lens: specialist" "$TMP_ROOT/plan.out" || fail "role lens missing"
grep -Fq "ticket claim QRD-0001" "$TMP_ROOT/plan.out" || fail "copyable command missing"

# Goal filter excludes unlinked tickets.
./bin/palari run --dry-run --goal GOAL-0001 >"$TMP_ROOT/goal.out"
grep -Eq '^next +QRD-0001' "$TMP_ROOT/goal.out" || fail "goal-linked ticket missing under filter"
if grep -Eq '^(next|stop) +QRD-0002' "$TMP_ROOT/goal.out"; then
	fail "goal filter should exclude unlinked tickets"
fi

# Over-broad scope is skipped with a reason.
./bin/palari ticket create QRD-0003 "Too broad" --goal GOAL-0001 \
	--allowed "**" --verify "true" >/dev/null
./bin/palari run --dry-run >"$TMP_ROOT/broad.out"
grep -Eq '^skip +QRD-0003' "$TMP_ROOT/broad.out" ||
	fail "over-broad ticket should be skipped"
grep -Fq 'scope is too broad' "$TMP_ROOT/broad.out" ||
	fail "skip reason for broad scope missing"
rm -f tickets/open/QRD-0003-*.md

# JSON output is well-formed and carries the same plan.
./bin/palari run --dry-run --json >"$TMP_ROOT/plan.json"
python3 - "$TMP_ROOT/plan.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["mode"] == "dry-run"
kinds = {item["id"]: item["kind"] for item in data["plan"]}
assert kinds.get("DEC-0001") == "stop", kinds
assert kinds.get("QRD-0002") == "stop", kinds
assert kinds.get("QRD-0001") == "next", kinds
assert data["planned"] >= 1
PYEOF

printf 'queue-dry-run: ok\n'
