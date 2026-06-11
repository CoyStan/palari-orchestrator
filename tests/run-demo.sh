#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*
git init -b main >/dev/null
git config user.email "demo@example.invalid"
git config user.name "Demo Test"
git add .
git commit -m "demo baseline" >/dev/null

./bin/palari demo >"$TMP_ROOT/demo.out"
grep -Fq "demo: wrote local Palari operator fixtures" "$TMP_ROOT/demo.out"
grep -Fq "ticket: DEM-0001 in-review with reports and evidence" "$TMP_ROOT/demo.out"
grep -Fq "ticket: DEM-0002 needs human approval before implementation" "$TMP_ROOT/demo.out"

test -f tickets/open/DEM-0001-operator-console-quickstart.md
test -f tickets/open/DEM-0002-human-approval-gate.md
test -f reports/DEM-0001-technical-report.md
test -f reports/DEM-0001-reviewer-note.md
test -f reports/human/DEM-0002-human-report.md
test -f handoffs/DEM-0002-handoff.md
test -f reports/evidence/DEM-0001/verification.log
test -f reports/evidence/DEM-0001/junit.xml
test -f reports/evidence/DEM-0001/palari.sarif
test -f reports/evidence/DEM-0001/manifest.json

grep -Fq "status: in-review" tickets/open/DEM-0001-operator-console-quickstart.md
grep -Fq "created_by_role: ROLE-ENGINEERING-LEAD" tickets/open/DEM-0001-operator-console-quickstart.md
grep -Fq "delegated_to_role: ROLE-SPECIALIST" tickets/open/DEM-0001-operator-console-quickstart.md
grep -Fq "status: needs-human" tickets/open/DEM-0002-human-approval-gate.md
grep -Fq "requires_human_confirmation: true" tickets/open/DEM-0002-human-approval-gate.md

./bin/palari lint DEM-0001 >"$TMP_ROOT/lint-demo-1.out"
grep -Fq "lint: ok for DEM-0001" "$TMP_ROOT/lint-demo-1.out"
./bin/palari lint DEM-0002 >"$TMP_ROOT/lint-demo-2.out"
grep -Fq "lint: ok for DEM-0002" "$TMP_ROOT/lint-demo-2.out"
./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
grep -Fq '"id":"DEM-0001"' "$TMP_ROOT/snapshot.json"
grep -Fq '"status":"in-review"' "$TMP_ROOT/snapshot.json"
grep -Fq '"has_manifest":true' "$TMP_ROOT/snapshot.json"
grep -Fq '"id":"DEM-0002"' "$TMP_ROOT/snapshot.json"
grep -Fq '"status":"needs-human"' "$TMP_ROOT/snapshot.json"

if ./bin/palari demo >"$TMP_ROOT/demo-again.out" 2>&1; then
	printf 'demo: expected second run to require --force\n' >&2
	exit 1
fi
grep -Fq "pass --force to replace demo fixtures" "$TMP_ROOT/demo-again.out"
./bin/palari demo --force >"$TMP_ROOT/demo-force.out"
grep -Fq "demo: wrote local Palari operator fixtures" "$TMP_ROOT/demo-force.out"

# New fixtures: demo goal links both tickets and one open decision exists.
[[ -f goals/active/GOAL-0099-demo-evaluate-palari-governance.md ]] ||
	fail "demo goal fixture missing"
grep -Fq "serves_goal: GOAL-0099" tickets/open/DEM-0001-*.md ||
	fail "DEM-0001 not linked to demo goal"
[[ -f decisions/open/DEC-0099-demo-choose-console-refresh-interval.md ]] ||
	fail "demo decision fixture missing"
./bin/palari run --dry-run >"$TMP_ROOT/demo-plan.out"
grep -Eq '^stop +DEC-0099' "$TMP_ROOT/demo-plan.out" ||
	fail "dry-run should surface the demo decision as a stop item"

printf 'demo: ok\n'
