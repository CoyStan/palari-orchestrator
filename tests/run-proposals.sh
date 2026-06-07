#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-proposals.sh
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "proposal@example.invalid"
git config user.name "Proposal Test"

./bin/palari init >/dev/null
test -d tickets/proposed
test -d reports/planning

./bin/palari propose create POS-PROP-0001 "Plan executor split" \
	--planner openclaude \
	--model deepseek/deepseek-v4-flash \
	--source "proposal-test" \
	--intent "Define one bounded docs ticket for an external executor." >"$TMP_ROOT/propose-create.out"

grep -Fq "propose create: tickets/proposed/POS-PROP-0001-plan-executor-split.md" "$TMP_ROOT/propose-create.out"
grep -Fq "lead packet: reports/planning/POS-PROP-0001-lead-packet.md" "$TMP_ROOT/propose-create.out"
test -f tickets/proposed/POS-PROP-0001-plan-executor-split.md
test -f reports/planning/POS-PROP-0001-lead-packet.md

grep -Fq "planner: openclaude" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "model: deepseek/deepseek-v4-flash" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "Define one bounded docs ticket" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "The lead may not implement code" tickets/proposed/POS-PROP-0001-plan-executor-split.md

./bin/palari propose packet POS-PROP-0001 >"$TMP_ROOT/lead.packet"
./bin/palari lead propose packet POS-PROP-0001 >"$TMP_ROOT/lead-alias.packet"
grep -Fq "Palari Lead planning packet" "$TMP_ROOT/lead.packet"
grep -Fq "Palari Lead planning packet" "$TMP_ROOT/lead-alias.packet"
grep -Fq "Role: lead" "$TMP_ROOT/lead.packet"
grep -Fq "Write only proposal files under tickets/proposed" "$TMP_ROOT/lead.packet"
grep -Fq "Do not edit source files" "$TMP_ROOT/lead.packet"
grep -Fq "skills/planner/SKILL.md" "$TMP_ROOT/lead.packet"

./bin/palari propose list >"$TMP_ROOT/propose-list.out"
grep -Fq $'POS-PROP-0001	proposed	openclaude	-' "$TMP_ROOT/propose-list.out"
./bin/palari propose show POS-PROP-0001 >"$TMP_ROOT/propose-show.out"
grep -Fq "# POS-PROP-0001 Plan executor split" "$TMP_ROOT/propose-show.out"

./bin/palari status >"$TMP_ROOT/status.out"
grep -Fq "proposals: 1 proposed" "$TMP_ROOT/status.out"

./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
python3 - "$TMP_ROOT/snapshot.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text())
assert payload["counts"]["proposals"] == 1
assert payload["proposals"][0]["id"] == "POS-PROP-0001"
assert payload["proposals"][0]["planner"] == "openclaude"
assert payload["proposals"][0]["model"] == "deepseek/deepseek-v4-flash"
PY

if ./bin/palari propose adopt POS-PROP-0001 --ticket POS-0090 >"$TMP_ROOT/bad-adopt.out" 2>&1; then
	printf 'proposals: expected adopt without scope to fail\n' >&2
	exit 1
fi
grep -Fq "ticket create needs at least one --allowed path" "$TMP_ROOT/bad-adopt.out"

./bin/palari propose adopt POS-PROP-0001 \
	--ticket POS-0090 \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual proposal adoption check" \
	--review >"$TMP_ROOT/adopt.out"

grep -Fq "ticket create: tickets/open/POS-0090-plan-executor-split.md" "$TMP_ROOT/adopt.out"
grep -Fq "propose adopt: POS-PROP-0001 -> POS-0090" "$TMP_ROOT/adopt.out"
test -f tickets/open/POS-0090-plan-executor-split.md
grep -Fq "status: adopted" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "adopted_ticket: POS-0090" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "## Adoption" tickets/proposed/POS-PROP-0001-plan-executor-split.md
grep -Fq "requires_review: true" tickets/open/POS-0090-plan-executor-split.md

if ./bin/palari propose adopt POS-PROP-0001 --ticket POS-0091 >"$TMP_ROOT/second-adopt.out" 2>&1; then
	printf 'proposals: expected second adoption to fail\n' >&2
	exit 1
fi
grep -Fq "is not proposed; current status: adopted" "$TMP_ROOT/second-adopt.out"

./bin/palari propose lint POS-PROP-0001 >"$TMP_ROOT/propose-lint.out"
grep -Fq "propose lint: ok for POS-PROP-0001" "$TMP_ROOT/propose-lint.out"
./bin/palari lint >"$TMP_ROOT/lint.out"
grep -Fq "propose lint: ok" "$TMP_ROOT/lint.out"
grep -Fq "lint: ok" "$TMP_ROOT/lint.out"

printf 'proposals: ok\n'
