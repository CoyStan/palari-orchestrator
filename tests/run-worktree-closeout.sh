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
git config user.email "closeout@example.invalid"
git config user.name "Closeout Test"

./bin/palari init --ci --hooks >/dev/null
git add .
git commit -m "initial orchestrator package" >/dev/null

./bin/palari ticket create WTC-0001 "Closeout happy path" \
	--stream process \
	--risk R3 \
	--allowed "docs/worktree/**" \
	--allowed "tickets/open/WTC-0001-*" \
	--allowed "reports/WTC-0001-technical-report.md" \
	--allowed "reports/human/WTC-0001-human-report.md" \
	--allowed "reports/evidence/WTC-0001/**" \
	--verify "test -f docs/worktree/notes.md" >/dev/null
git add tickets/open/WTC-0001-*.md
git commit -m "route WTC-0001" >/dev/null

./bin/palari ticket create WTC-0002 "Closeout scope failure" \
	--stream process \
	--risk R1 \
	--allowed "docs/allowed/**" \
	--allowed "tickets/open/WTC-0002-*" \
	--allowed "reports/evidence/WTC-0002/**" \
	--verify "true" >/dev/null
git add tickets/open/WTC-0002-*.md
git commit -m "route WTC-0002" >/dev/null

if ./bin/palari worktree closeout WTC-0001 >"$TMP_ROOT/wrong-checkout.out" 2>&1; then
	printf 'closeout: expected wrong checkout to fail\n' >&2
	exit 1
fi
grep -Fq "state: wrong-checkout" "$TMP_ROOT/wrong-checkout.out"
grep -Fq "next: ./bin/palari worktree WTC-0001" "$TMP_ROOT/wrong-checkout.out"
grep -Fq "expected worktree: $TMP_ROOT/palari-orchestrator-worktrees/WTC-0001" "$TMP_ROOT/wrong-checkout.out"

./bin/palari worktree WTC-0001 >"$TMP_ROOT/worktree.out"
WTC1_WORKTREE="$(sed -n 's/^Worker cd: cd //p' "$TMP_ROOT/worktree.out")"
[[ -n "$WTC1_WORKTREE" ]]
cd "$WTC1_WORKTREE"

./bin/palari worktree WTC-0002 >"$TMP_ROOT/stacked-worktree.out"
WTC2_FLAT_WORKTREE="$TMP_ROOT/palari-orchestrator-worktrees/WTC-0002"
grep -Fq "Ticket worktree: $WTC2_FLAT_WORKTREE" "$TMP_ROOT/stacked-worktree.out"
grep -Fq "Worker cd: cd $WTC2_FLAT_WORKTREE" "$TMP_ROOT/stacked-worktree.out"
if grep -Fq "/WTC-0001/palari-orchestrator-worktrees/" "$TMP_ROOT/stacked-worktree.out"; then
	printf 'closeout: stacked worktree used a nested worktree base\n' >&2
	exit 1
fi
./bin/palari snapshot --json >"$TMP_ROOT/stacked-snapshot.json"
python3 - "$TMP_ROOT/stacked-snapshot.json" "$WTC2_FLAT_WORKTREE" <<'PY'
import json
import sys

snapshot = json.load(open(sys.argv[1], encoding="utf-8"))
tickets = {ticket["id"]: ticket for ticket in snapshot["tickets"]}
actual = tickets["WTC-0002"]["worktree"]
expected = sys.argv[2]
assert actual == expected, f"snapshot worktree mismatch: {actual!r} != {expected!r}"
PY

./bin/palari ticket claim WTC-0001 closeout-tester --allow-overlap >/dev/null
mkdir -p docs/worktree
printf 'worktree closeout note\n' >docs/worktree/notes.md

if ./bin/palari worktree closeout WTC-0001 >"$TMP_ROOT/dirty.out" 2>&1; then
	printf 'closeout: expected dirty worktree to fail\n' >&2
	exit 1
fi
grep -Fq "state: dirty" "$TMP_ROOT/dirty.out"
grep -Fq "next: commit, stash, or remove unrelated local changes" "$TMP_ROOT/dirty.out"

git add docs/worktree/notes.md tickets/open/WTC-0001-*.md
git commit -m "implement WTC-0001" >/dev/null

if ./bin/palari worktree closeout WTC-0001 >"$TMP_ROOT/missing-evidence.out" 2>&1; then
	printf 'closeout: expected missing evidence to fail\n' >&2
	exit 1
fi
grep -Fq "state: missing-evidence" "$TMP_ROOT/missing-evidence.out"
grep -Fq "next: ./bin/palari ci WTC-0001 --base main" "$TMP_ROOT/missing-evidence.out"

./bin/palari ci WTC-0001 --base main >/dev/null
git add reports/evidence/WTC-0001
git commit -m "record WTC-0001 evidence" >/dev/null

if ./bin/palari worktree closeout WTC-0001 >"$TMP_ROOT/missing-reports.out" 2>&1; then
	printf 'closeout: expected missing reports to fail\n' >&2
	exit 1
fi
grep -Fq "state: missing-reports" "$TMP_ROOT/missing-reports.out"
grep -Fq "reports: missing" "$TMP_ROOT/missing-reports.out"
grep -Fq "next: complete the missing reports, then run ./bin/palari report-lint WTC-0001" "$TMP_ROOT/missing-reports.out"

mkdir -p reports/human
cat >reports/WTC-0001-technical-report.md <<'DOC'
# WTC-0001 Technical Report

## Files Changed

- docs/worktree/notes.md

## Verification

- test -f docs/worktree/notes.md

## CI Evidence

- Refreshed by Palari CI.

## Risks / Follow-Ups

- None.
DOC
cat >reports/human/WTC-0001-human-report.md <<'DOC'
# WTC-0001 Human Report

## Why This Mattered

The closeout helper must guide agents without manual copy steps.

## What Changed

A safe fixture note was added for the closeout happy path.

## What I Should Know

This report is part of the focused closeout regression fixture.

## What To Check

Confirm closeout distinguishes pending and ready states.

## Recommended Next Move

Move the ticket to review only after evidence exists.
DOC
git add reports/WTC-0001-technical-report.md reports/human/WTC-0001-human-report.md
git commit -m "record WTC-0001 reports" >/dev/null

./bin/palari worktree closeout WTC-0001 >"$TMP_ROOT/ready.out"
grep -Fq "state: ready-for-review" "$TMP_ROOT/ready.out"
grep -Fq "scope: ok" "$TMP_ROOT/ready.out"
grep -Fq "evidence: ready" "$TMP_ROOT/ready.out"
grep -Fq "reports: ready" "$TMP_ROOT/ready.out"
grep -Fq "next: ./bin/palari ticket ready WTC-0001" "$TMP_ROOT/ready.out"
grep -Fq "next: ./bin/palari packet WTC-0001 reviewer" "$TMP_ROOT/ready.out"

cd "$WORK"
./bin/palari worktree WTC-0002 >"$TMP_ROOT/worktree2.out"
WTC2_WORKTREE="$(sed -n 's/^Worker cd: cd //p' "$TMP_ROOT/worktree2.out")"
[[ -n "$WTC2_WORKTREE" ]]
cd "$WTC2_WORKTREE"
./bin/palari ticket claim WTC-0002 closeout-tester --allow-overlap >/dev/null
printf 'outside declared scope\n' >outside.txt
git add tickets/open/WTC-0002-*.md outside.txt
git commit -m "create out-of-scope change" >/dev/null

if ./bin/palari worktree closeout WTC-0002 >"$TMP_ROOT/scope-failed.out" 2>&1; then
	printf 'closeout: expected scope failure to fail\n' >&2
	exit 1
fi
grep -Fq "state: scope-failed" "$TMP_ROOT/scope-failed.out"
grep -Fq "scope: failed" "$TMP_ROOT/scope-failed.out"
grep -Fq "next: ./bin/palari scope-check WTC-0002 --base main" "$TMP_ROOT/scope-failed.out"

printf 'worktree-closeout: ok\n'
