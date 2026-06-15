#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP_ROOT="$(mktemp -d)"
  WORK="$TMP_ROOT/repo"
  mkdir -p "$WORK"
  (cd "$REPO_ROOT" && tar --exclude .git --exclude repomix-output.xml -cf - .) | (cd "$WORK" && tar -xf -)
  cd "$WORK"
  chmod +x bin/palari scripts/palari
  git init -b main >/dev/null
  git config user.email "bats@example.invalid"
  git config user.name "Bats Test"
  ./bin/palari init >/dev/null
  git add .
  git commit -m "initial" >/dev/null
}

teardown() {
  rm -rf "$TMP_ROOT"
}

@test "accept rejects forged evidence manifest" {
  ./bin/palari ticket create POS-0100 "Forged evidence" \
    --stream docs \
    --risk R1 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "manual forged evidence check" >/dev/null
  ./bin/palari ticket claim POS-0100 implementer >/dev/null
  mkdir -p reports/evidence/POS-0100
  printf 'forged log\n' > reports/evidence/POS-0100/verification.log
  printf '<testsuite tests="1" failures="0"></testsuite>\n' > reports/evidence/POS-0100/junit.xml
  printf '{"version":"2.1.0","runs":[]}\n' > reports/evidence/POS-0100/palari.sarif
  printf '{"ticket":"POS-0100","status":"passed","head_sha":"forged"}\n' > reports/evidence/POS-0100/manifest.json
  ./bin/palari ticket ready POS-0100 >/dev/null

  run ./bin/palari accept POS-0100 --by reviewer

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid evidence manifest"* ]]
}

@test "palari ci writes an integrity manifest" {
  ./bin/palari ticket create POS-0101 "Integrity manifest" \
    --stream docs \
    --risk R1 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "manual integrity check" >/dev/null
  ./bin/palari ticket claim POS-0101 implementer >/dev/null

  run ./bin/palari ci POS-0101

  [ "$status" -eq 0 ]
  grep -Fq '"generator": "palari-ci"' reports/evidence/POS-0101/manifest.json
  grep -Fq '"sha256":' reports/evidence/POS-0101/manifest.json
}

@test "R5 acceptance requires two authorized human profiles" {
  ./bin/palari human create HUMAN-R5A "R5 Approver A" \
    --skill governance:L5 \
    --role founder \
    --capacity-hgl 60 \
    --authority-max-risk R5 \
    --may-approve-policy-changes >/dev/null
  ./bin/palari human adopt HUMAN-R5A --by founder >/dev/null
  ./bin/palari human create HUMAN-R5B "R5 Approver B" \
    --skill governance:L5 \
    --role founder \
    --capacity-hgl 60 \
    --authority-max-risk R5 \
    --may-approve-policy-changes >/dev/null
  ./bin/palari human adopt HUMAN-R5B --by founder >/dev/null
  ./bin/palari human create HUMAN-R2A "R2 Approver" \
    --skill governance:L5 \
    --role reviewer \
    --capacity-hgl 60 \
    --authority-max-risk R2 >/dev/null
  ./bin/palari human adopt HUMAN-R2A --by founder >/dev/null
  git add humans
  git commit -m "human fixtures" >/dev/null

  ./bin/palari ticket create POS-0102 "R5 accept gate" \
    --stream process \
    --risk R5 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "true" >/dev/null
  ./bin/palari ticket claim POS-0102 implementer >/dev/null
  cat >reports/POS-0102-technical-report.md <<'DOC'
# POS-0102 Technical Report

## Files Changed

- `tickets/open/POS-0102-r5-accept-gate.md`

## Verification

- `true`

## CI Evidence

- `palari ci POS-0102`

## Risks / Follow-Ups

- Test fixture only.
DOC
  cat >reports/POS-0102-reviewer-note.md <<'DOC'
# POS-0102 Reviewer Note

## Review Result

Accept-ready fixture.

## Findings

No blocking findings.

## Verification Reviewed

- `palari ci POS-0102`

## Required Changes

None.

## Recommendation

Accept with two R5-authorized humans.
DOC
  mkdir -p reports/human
  cat >reports/human/POS-0102-human-report.md <<'DOC'
# POS-0102 Human Report

## Why This Mattered

R5 acceptance must require two authorized humans.

## What Changed

Test-only fixture.

## What I Should Know

No production governance setting is changed by this fixture.

## What To Check

R5 accept refuses unsafe acceptor combinations and accepts two R5 humans.

## Recommended Next Move

Keep R5 dual-human acceptance enforced.
DOC

  ./bin/palari ci POS-0102 >/dev/null
  ./bin/palari ticket ready POS-0102 >/dev/null

  run ./bin/palari accept POS-0102 --by HUMAN-R5A
  [ "$status" -ne 0 ]
  [[ "$output" == *"R5 tickets require --co-by"* ]]

  run ./bin/palari accept POS-0102 --by HUMAN-R5A --co-by HUMAN-R5A
  [ "$status" -ne 0 ]
  [[ "$output" == *"two distinct humans"* ]]

  run ./bin/palari accept POS-0102 --by HUMAN-R5A --co-by HUMAN-R2A
  [ "$status" -ne 0 ]
  [[ "$output" == *"authority_max_risk R2"* ]]

  run ./bin/palari accept POS-0102 --by HUMAN-R5A --co-by HUMAN-R5B
  [ "$status" -eq 0 ]
  [[ "$output" == *"co-accepted-by: HUMAN-R5B"* ]]
  grep -Fq "co_accepted_by: HUMAN-R5B" tickets/closed/POS-0102-r5-accept-gate.md
  grep -Fq "acceptance_mode: human_dual" tickets/closed/POS-0102-r5-accept-gate.md
}
