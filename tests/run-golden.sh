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
git init -b main >/dev/null
git config user.email "golden@example.invalid"
git config user.name "Golden Test"

./bin/palari init --ci --hooks > "$TMP_ROOT/init.out"
test -f .github/workflows/palari.yml
test -f .github/palari-required-checks.ruleset.json
test -f lefthook.yml
test -f adapters/web/server.py
test -f adapters/web/static/index.html
test -f adapters/web/static/styles.css
test -f adapters/web/static/app.js
test -f reports/evidence/.gitkeep
grep -Fq "workflow alone does not protect merges" "$TMP_ROOT/init.out"
grep -Fq "gh api --method POST repos/OWNER/REPO/rulesets" "$TMP_ROOT/init.out"
python3 -m py_compile adapters/web/server.py
./bin/palari snapshot --json > "$TMP_ROOT/snapshot.out"
grep -Fq '"project": "Palari Orchestrator"' "$TMP_ROOT/snapshot.out"
grep -Fq '"tickets": []' "$TMP_ROOT/snapshot.out"
./bin/palari web --check > "$TMP_ROOT/web-snapshot.out"
grep -Fq '"project": "Palari Orchestrator"' "$TMP_ROOT/web-snapshot.out"
grep -Fq '"tickets": []' "$TMP_ROOT/web-snapshot.out"

./bin/palari skill create sample-feature \
  --description "Preserve the sample feature contract for golden tests." > "$TMP_ROOT/skill.out"

test -f agent-skills/sample-feature/SKILL.md
grep -Fq "skill create: agent-skills/sample-feature/SKILL.md" "$TMP_ROOT/skill.out"
while IFS= read -r expected; do
  [[ -n "$expected" ]] || continue
  grep -Fq "$expected" agent-skills/sample-feature/SKILL.md
done < "$REPO_ROOT/tests/golden/skill.contains.txt"

./bin/palari mcp manifest > "$TMP_ROOT/mcp.out"
grep -Fq "palari_ticket_claim" "$TMP_ROOT/mcp.out"
grep -Fq "palari_scope_check" "$TMP_ROOT/mcp.out"

./bin/palari github ruleset-command --repo CoyStan/palari-orchestrator > "$TMP_ROOT/ruleset-command.out"
grep -Fq "gh api --method POST repos/CoyStan/palari-orchestrator/rulesets" "$TMP_ROOT/ruleset-command.out"

if ./bin/palari ci > "$TMP_ROOT/no-ticket-ci.out" 2>&1; then
  printf 'golden: expected no-ticket ci to fail closed\n' >&2
  exit 1
fi
grep -Fq "ci requires a ticket ID" "$TMP_ROOT/no-ticket-ci.out"
./bin/palari ci --repo-only > "$TMP_ROOT/repo-ci.out"
grep -Fq "ci: ok for repo" "$TMP_ROOT/repo-ci.out"
rm -rf reports/evidence/repo

./bin/palari ticket create POS-0002 "Overlap alpha" \
  --stream docs \
  --risk R1 \
  --allowed "docs/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "manual overlap check" >/dev/null
if grep -Eq '^(level|parent_id|root_id|children|agents_allowed|claim_token|product_feel_review):' tickets/open/POS-0002-overlap-alpha.md; then
  printf 'golden: lean R1 ticket generated a demoted core field\n' >&2
  exit 1
fi
if grep -Fq "Ticket Completion Contract" tickets/open/POS-0002-overlap-alpha.md; then
  printf 'golden: lean R1 ticket generated the heavy completion contract\n' >&2
  exit 1
fi
./bin/palari ticket create POS-0003 "Overlap beta" \
  --stream docs \
  --risk R1 \
  --allowed "docs/golden/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "manual overlap check" >/dev/null
if ./bin/palari scope-overlaps POS-0002 > "$TMP_ROOT/overlap.out" 2>&1; then
  printf 'golden: expected overlapping scopes to fail\n' >&2
  exit 1
fi
grep -Fq "scope-overlaps: POS-0002 overlaps POS-0003" "$TMP_ROOT/overlap.out"
if ./bin/palari ticket claim POS-0002 overlap-tester > "$TMP_ROOT/overlap-claim.out" 2>&1; then
  printf 'golden: expected overlapping claim to fail under block policy\n' >&2
  exit 1
fi
grep -Fq "overlapping allowed_paths" "$TMP_ROOT/overlap-claim.out"

cat > oops.txt <<'DOC'
outside declared ticket scope
DOC
if ./bin/palari ci POS-0002 > "$TMP_ROOT/failing-ci.out" 2>&1; then
  printf 'golden: expected out-of-scope ci to fail\n' >&2
  exit 1
fi
grep -Fq "ci: failed for POS-0002" "$TMP_ROOT/failing-ci.out"
grep -Fq '"runAutomationDetails": {"id": "palari/POS-0002"}' reports/evidence/POS-0002/palari.sarif
grep -Fq '"locations"' reports/evidence/POS-0002/palari.sarif
rm -f oops.txt
rm -rf reports/evidence/POS-0002
rm -f tickets/open/POS-0002-*.md tickets/open/POS-0003-*.md

./bin/palari ticket create POS-0004 "Claim lease check" \
  --stream docs \
  --risk R1 \
  --allowed "lease/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "manual claim check" >/dev/null
./bin/palari ticket claim POS-0004 first-claimant >/dev/null
if ./bin/palari ticket claim POS-0004 second-claimant > "$TMP_ROOT/second-claim.out" 2>&1; then
  printf 'golden: expected second active claim to fail\n' >&2
  exit 1
fi
grep -Fq "already claimed" "$TMP_ROOT/second-claim.out"
git update-ref -d refs/palari/claims/POS-0004 >/dev/null 2>&1 || true
rm -f tickets/open/POS-0004-*.md

git add .
git commit -m "initial orchestrator package" >/dev/null

./bin/palari ticket create POS-0001 "Golden flow scope review" \
  --stream docs \
  --risk R1 \
  --allowed "docs/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "manual golden check" \
  --review \
  --product-feel required >/dev/null

git add tickets
git commit -m "add golden ticket" >/dev/null

./bin/palari worktree POS-0001 > "$TMP_ROOT/worktree.out"
./bin/palari packet POS-0001 specialist > "$TMP_ROOT/specialist.packet"

while IFS= read -r expected; do
  [[ -n "$expected" ]] || continue
  grep -Fq "$expected" "$TMP_ROOT/specialist.packet"
done < "$REPO_ROOT/tests/golden/packet.contains.txt"

WT="$(awk -F': ' '/Ticket worktree:/ { print $2 }' "$TMP_ROOT/worktree.out")"
[[ -n "$WT" && -d "$WT" ]] || {
  printf 'golden: missing worktree from output\n' >&2
  exit 1
}

cd "$WT"
./bin/palari ticket claim POS-0001 test-specialist >/dev/null
./bin/palari ticket heartbeat POS-0001 >/dev/null
mkdir -p docs reports reports/human

cat > docs/golden.md <<'DOC'
# Golden Flow

This document proves a scoped, allowed-path edit.
DOC

./bin/palari ci POS-0001 > "$TMP_ROOT/ci.out"
grep -Fq "ci: ok for POS-0001" "$TMP_ROOT/ci.out"
test -f reports/evidence/POS-0001/verification.log
test -f reports/evidence/POS-0001/junit.xml
test -f reports/evidence/POS-0001/palari.sarif

cat > reports/POS-0001-technical-report.md <<'DOC'
# POS-0001 Technical Report

## Session

- Ticket: POS-0001
- Role: specialist
- Result: in-review

## Files Changed

```text
docs/golden.md
```

## Outcome

- What changed: Added the golden flow document.
- What did not change: No app or production paths changed.
- Blockers: None.
- Next action: Review.

## Verification

- Passed: manual golden check
- Failed: none
- Not run: none

## CI Evidence

- CI run: local golden flow
- Evidence bundle: reports/evidence/POS-0001
- JUnit: reports/evidence/POS-0001/junit.xml
- SARIF: reports/evidence/POS-0001/palari.sarif
- Attestation: not configured for golden flow

## Review Status

- Review status: pending
- Reviewer note:

## Risks / Follow-Ups

- None.
DOC

cat > reports/POS-0001-reviewer-note.md <<'DOC'
# POS-0001 Reviewer Note

## Review Result

Decision: accept

## Findings

- No blocking findings.

## Verification Reviewed

- Reviewed docs/golden.md and scope output.

## Required Changes

- None.

## Recommendation

Accept.
DOC

cat > reports/POS-0001-product-feel-review.md <<'DOC'
# POS-0001 Product Feel Review

## Review Result

Decision: accept

## Findings

- Not applicable to rendered UI; the custom product-feel report is explicitly satisfied as documentation-only.

## Verification Reviewed

- Reviewed the ticket and docs/golden.md.

## Required Changes

- None.

## Recommendation

Accept from the product-feel axis.
DOC

cat > reports/human/POS-0001-human-report.md <<'DOC'
# POS-0001 Human Report

## Why This Mattered

This proves the portable orchestration flow can carry evidence to acceptance.

## What Changed

- Added a scoped golden-flow document.

## What I Should Know

- The test stayed inside allowed paths.

## What To Check

- Path: docs/golden.md
- Command: ./bin/palari scope-check POS-0001

## Recommended Next Move

Use this as the smoke test for v1 changes.
DOC

./bin/palari scope-check POS-0001 > "$TMP_ROOT/scope.out"
./bin/palari ticket ready POS-0001 >/dev/null
./bin/palari ticket heartbeat POS-0001 0 >/dev/null
sleep 1
if ./bin/palari accept POS-0001 --by founder > "$TMP_ROOT/expired-accept.out" 2>&1; then
  printf 'golden: expected expired claim acceptance to fail\n' >&2
  exit 1
fi
grep -Fq "claim lease is expired" "$TMP_ROOT/expired-accept.out"
./bin/palari ticket heartbeat POS-0001 >/dev/null
./bin/palari lint POS-0001 > "$TMP_ROOT/lint.out"
./bin/palari accept POS-0001 --by founder > "$TMP_ROOT/accept.out"
./bin/palari status > "$TMP_ROOT/status.out"

grep -Fq "scope-check: ok for POS-0001" "$TMP_ROOT/scope.out"
grep -Fq "lint: ok for POS-0001" "$TMP_ROOT/lint.out"
grep -Fq "accept: POS-0001 accepted by founder" "$TMP_ROOT/accept.out"

while IFS= read -r expected; do
  [[ -n "$expected" ]] || continue
  grep -Fq "$expected" "$TMP_ROOT/status.out"
done < "$REPO_ROOT/tests/golden/status.contains.txt"

test -f tickets/closed/POS-0001-golden-flow-scope-review.md
test ! -f tickets/open/POS-0001-golden-flow-scope-review.md

printf 'golden: ok\n'
