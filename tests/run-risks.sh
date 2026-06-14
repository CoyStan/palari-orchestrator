#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'risks: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari

git init -b main >/dev/null
git config user.email "risks@example.invalid"
git config user.name "Risks Test"
git add .
git commit -m "risks baseline" >/dev/null

./bin/palari ticket create RSK-0001 "Governance kernel change" \
	--risk R5 \
	--allowed "contracts/**" \
	--allowed "tickets/open/RSK-0001*" \
	--allowed "tickets/closed/RSK-0001*" \
	--allowed "reports/**" \
	--verify "test -f contracts/company-ai-os.md" >"$TMP_ROOT/r5-create.out"

grep -Fq "ticket create:" "$TMP_ROOT/r5-create.out" || fail "R5 ticket creation did not succeed"
grep -Fq "risk: R5" tickets/open/RSK-0001-governance-kernel-change.md ||
	fail "R5 ticket risk was not written"
grep -Fq "requires_human_confirmation: true" tickets/open/RSK-0001-governance-kernel-change.md ||
	fail "R5 ticket should require human confirmation"
grep -Fq "requires_review: true" tickets/open/RSK-0001-governance-kernel-change.md ||
	fail "R5 ticket should require review"
grep -Fq "## Ticket Completion Contract" tickets/open/RSK-0001-governance-kernel-change.md ||
	fail "R5 ticket should include the heavier completion contract"

if ./bin/palari ticket create RSK-0002 "Invalid risk" \
	--risk R6 \
	--allowed "contracts/**" \
	--verify "true" >"$TMP_ROOT/r6-create.out" 2>&1; then
	fail "R6 ticket creation should fail"
fi
grep -Fq "invalid risk: R6" "$TMP_ROOT/r6-create.out" ||
	fail "R6 failure should explain invalid risk"

./bin/palari role lint >"$TMP_ROOT/role-lint.out"
grep -Fq "role lint: ok" "$TMP_ROOT/role-lint.out" ||
	fail "role lint should accept ROLE-ROOT max_risk R5"

./bin/palari model routes >"$TMP_ROOT/routes.out"
grep -Fq "R5  -> frontier" "$TMP_ROOT/routes.out" ||
	fail "R5 should route to frontier"

./bin/palari ticket claim RSK-0001 tester >/dev/null
cat >reports/RSK-0001-technical-report.md <<'DOC'
# RSK-0001 Technical Report

## Files Changed

- `contracts/company-ai-os.md`

## Verification

- `test -f contracts/company-ai-os.md`

## CI Evidence

- Pending.

## Risks / Follow-Ups

- Test fixture only.
DOC

cat >reports/RSK-0001-reviewer-note.md <<'DOC'
# RSK-0001 Reviewer Note

## Review Result

Reopen unless a founder report is present.

## Findings

This fixture confirms that R5 work is treated as governance-sensitive and must
carry a founder/human gate before report lint and evidence readiness are
complete.

## Verification Reviewed

- `palari evidence score RSK-0001`

## Required Changes

Add the missing human report before accepting.

## Recommendation

Keep the ticket blocked from acceptance until a founder report exists.
DOC

./bin/palari ticket ready RSK-0001 >/dev/null
if ./bin/palari report-lint RSK-0001 >"$TMP_ROOT/report-no-human.out" 2>&1; then
	fail "R5 in-review ticket should require a human/founder report"
fi
grep -Fq "missing human/founder report" "$TMP_ROOT/report-no-human.out" ||
	fail "R5 report-lint should name missing human report"

./bin/palari evidence score RSK-0001 >"$TMP_ROOT/evidence-r5.out"
grep -Fq "human/founder report" "$TMP_ROOT/evidence-r5.out" ||
	fail "R5 evidence score should include human/founder report gate"

mkdir -p reports/human
cat >reports/human/RSK-0001-human-report.md <<'DOC'
# RSK-0001 Human Report

## Why This Mattered

R5 fixtures need to prove that governance-sensitive work carries a human gate.

## What Changed

Founder reviewed this R5 fixture and confirms it is test-only.

## What I Should Know

No real governance setting is being accepted by this fixture.

## What To Check

Report lint should pass only after this human report exists.

## Recommended Next Move

Keep R5 human-gated in production workflows.
DOC

./bin/palari report-lint RSK-0001 >"$TMP_ROOT/report-with-human.out"
grep -Fq "report-lint: ok for RSK-0001" "$TMP_ROOT/report-with-human.out" ||
	fail "R5 report-lint should pass once human report exists"

printf 'risks: ok\n'
