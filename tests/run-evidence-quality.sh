#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'evidence-quality: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-evidence-quality.sh
rm -f tickets/open/*.md tickets/open/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "evidence@example.invalid"
git config user.name "Evidence Test"
git add .
git commit -m "evidence baseline" >/dev/null

./bin/palari ticket create EVD-0001 "Evidence scoring sample" \
	--risk R2 \
	--priority P1 \
	--allowed README.md \
	--allowed tickets/open/EVD-0001-*.md \
	--allowed tickets/closed/EVD-0001-*.md \
	--allowed reports/EVD-0001-technical-report.md \
	--allowed reports/EVD-0001-reviewer-note.md \
	--allowed reports/evidence/EVD-0001/** \
	--verify "test -f README.md" \
	--review \
	--contract >/dev/null

./bin/palari evidence score EVD-0001 >"$TMP_ROOT/missing.out"
grep -Fq "rating: needs-evidence" "$TMP_ROOT/missing.out" ||
	fail "missing evidence should be rated needs-evidence"
grep -Fq "missing +0  reports/evidence/EVD-0001/manifest.json" "$TMP_ROOT/missing.out" ||
	fail "missing manifest diagnostic not shown"
if ./bin/palari evidence score EVD-0001 --strict >"$TMP_ROOT/strict-missing.out" 2>&1; then
	fail "strict scoring should fail before evidence is complete"
fi

./bin/palari ticket claim EVD-0001 tester --allow-overlap >/dev/null

cat >reports/EVD-0001-technical-report.md <<'DOC'
# EVD-0001 Technical Report

## Files Changed

- `README.md`

## Verification

- `test -f README.md`

## CI Evidence

- `reports/evidence/EVD-0001/`

## Risks / Follow-Ups

- None.
DOC

cat >reports/EVD-0001-reviewer-note.md <<'DOC'
# EVD-0001 Reviewer Note

## Review Result

Ready for acceptance.

## Findings

No blocking findings.

## Verification Reviewed

- `test -f README.md`

## Required Changes

None.

## Recommendation

Accept after human review if desired.
DOC

./bin/palari ci EVD-0001 >/dev/null
./bin/palari ticket ready EVD-0001 >/dev/null

./bin/palari evidence score EVD-0001 >"$TMP_ROOT/complete.out"
grep -Fq "score: 100/100" "$TMP_ROOT/complete.out" ||
	fail "complete evidence should score 100"
grep -Fq "rating: ready" "$TMP_ROOT/complete.out" ||
	fail "complete evidence should be ready"
grep -Fq "next_action: human gate: ./bin/palari accept EVD-0001 --by HUMAN" "$TMP_ROOT/complete.out" ||
	fail "ready in-review ticket should point to human accept command"
./bin/palari evidence score EVD-0001 --strict >/dev/null

printf 'evidence-quality: ok\n'
