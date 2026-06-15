#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'outcomes: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-outcomes.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari outcomes/open/*.md outcomes/recorded/*.md workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md decisions/open/*.md decisions/decided/*.md memory/decisions/*.md
mkdir -p reports/evidence/OUT-9000

git init -b main >/dev/null
git config user.email "outcomes@example.invalid"
git config user.name "Outcomes Test"
git add .
git commit -m "outcomes baseline" >/dev/null

./bin/palari init >"$TMP_ROOT/init.out"
test -f outcomes/open/.gitkeep || fail "init should create outcomes/open"
test -f outcomes/recorded/.gitkeep || fail "init should create outcomes/recorded"
git add .
git commit -m "init outcome dirs" >/dev/null

./bin/palari workflow create WF-0001 "Outcome workflow" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R2 >/dev/null
./bin/palari workflow adopt WF-0001 --by founder >/dev/null

./bin/palari ticket create OUT-9000 "Outcome linked ticket" \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--verify "test -f README.md" >/dev/null
./bin/palari decide create DEC-0001 "Outcome linked decision" \
	--ticket OUT-9000 \
	--option "Ship small" \
	--option "Wait" \
	--recommend 1 >/dev/null
./bin/palari decide record DEC-0001 --choice 1 --by founder >/dev/null
printf 'evidence\n' >reports/evidence/OUT-9000/verification.log

./bin/palari outcome create OUT-0001 \
	--workflow WF-0001 \
	--status observed \
	--goal GOAL-0100 \
	--ticket OUT-9000 \
	--decision DEC-0001 \
	--evidence reports/evidence/OUT-9000/verification.log \
	--title "Outcome observed" >"$TMP_ROOT/create.out"
grep -Fq "outcome create: outcomes/open/OUT-0001-outcome-observed.md" "$TMP_ROOT/create.out" ||
	fail "outcome create path missing"
test -f outcomes/open/OUT-0001-outcome-observed.md || fail "open outcome missing"

./bin/palari outcome list >"$TMP_ROOT/list.out"
grep -Fq "open     OUT-0001" "$TMP_ROOT/list.out" ||
	fail "outcome list missing open record"
./bin/palari outcome list --workflow WF-0001 >"$TMP_ROOT/list-workflow.out"
grep -Fq "workflow:WF-0001" "$TMP_ROOT/list-workflow.out" ||
	fail "workflow-filtered list missing record"

./bin/palari outcome show OUT-0001 >"$TMP_ROOT/show.out"
grep -Fq "status: observed" "$TMP_ROOT/show.out" ||
	fail "outcome show missing status"
grep -Fq "ticket: OUT-9000" "$TMP_ROOT/show.out" ||
	fail "outcome show missing ticket link"

./bin/palari outcome lint >"$TMP_ROOT/lint-open.out"
grep -Fq "outcome lint: ok" "$TMP_ROOT/lint-open.out" ||
	fail "outcome lint should pass for open record"

./bin/palari outcome record OUT-0001 --by founder >"$TMP_ROOT/record.out"
grep -Fq "outcome record: OUT-0001 -> outcomes/recorded/OUT-0001-outcome-observed.md" "$TMP_ROOT/record.out" ||
	fail "outcome record output missing"
test -f outcomes/recorded/OUT-0001-outcome-observed.md || fail "recorded outcome missing"
grep -Fq "lifecycle: recorded" outcomes/recorded/OUT-0001-outcome-observed.md ||
	fail "record should set lifecycle recorded"

./bin/palari outcome lint >"$TMP_ROOT/lint-recorded.out"
grep -Fq "outcome lint: ok" "$TMP_ROOT/lint-recorded.out" ||
	fail "outcome lint should pass for recorded record"

if ./bin/palari outcome record OUT-0001 --by founder >/dev/null 2>&1; then
	fail "recorded outcome should not record twice"
fi

cat >outcomes/open/OUT-BAD-bad.md <<'DOC'
---
id: OUT-BAD
title: Bad outcome
status: observed
lifecycle: open
workflow: WF-9999
goal:
ticket:
decision:
linked_evidence:
created: 2026-01-01
updated: 2026-01-01
---

# OUT-BAD Bad outcome
DOC
if ./bin/palari outcome lint >"$TMP_ROOT/lint-bad.out" 2>&1; then
	fail "missing workflow should fail outcome lint"
fi
grep -Fq "references missing workflow: WF-9999" "$TMP_ROOT/lint-bad.out" ||
	fail "missing workflow diagnostic absent"
rm -f outcomes/open/OUT-BAD-bad.md

printf 'outcomes: ok\n'
