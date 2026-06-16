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

@test "human acceptance mode is explicit and policy mode cannot close tickets" {
  ./bin/palari ticket create POS-0103 "Human acceptance mode" \
    --stream docs \
    --risk R1 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "true" >/dev/null
  grep -Fq "acceptance_mode: human" tickets/open/POS-0103-human-acceptance-mode.md
  ./bin/palari ticket claim POS-0103 implementer >/dev/null
  cat >reports/POS-0103-technical-report.md <<'DOC'
# POS-0103 Technical Report

## Files Changed

- `tickets/open/POS-0103-human-acceptance-mode.md`

## Verification

- `true`

## CI Evidence

- `palari ci POS-0103`

## Risks / Follow-Ups

- Test fixture only.
DOC
  ./bin/palari ci POS-0103 >/dev/null
  ./bin/palari ticket ready POS-0103 >/dev/null

  perl -0pi -e 's/acceptance_mode: human/acceptance_mode: policy_simulation_only/' tickets/open/POS-0103-human-acceptance-mode.md
  run ./bin/palari accept POS-0103 --by reviewer
  [ "$status" -ne 0 ]
  [[ "$output" == *"policy acceptance is simulation-only in this Palari version"* ]]

  perl -0pi -e 's/acceptance_mode: policy_simulation_only/acceptance_mode: human/' tickets/open/POS-0103-human-acceptance-mode.md
  run ./bin/palari accept POS-0103 --by reviewer
  [ "$status" -eq 0 ]
  grep -Fq "acceptance_mode: human" tickets/closed/POS-0103-human-acceptance-mode.md
}

@test "R5 acceptance honors configured human approval quorum" {
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

Accept with the configured R5 human quorum.
DOC
  mkdir -p reports/human
  cat >reports/human/POS-0102-human-report.md <<'DOC'
# POS-0102 Human Report

## Why This Mattered

R5 acceptance must honor the configured human quorum.

## What Changed

Test-only fixture.

## What I Should Know

No production governance setting is changed by this fixture.

## What To Check

R5 accept refuses unsafe acceptors and accepts the configured quorum.

## Recommended Next Move

Keep configurable R5 quorum enforcement active.
DOC

  ./bin/palari ci POS-0102 >/dev/null
  ./bin/palari ticket ready POS-0102 >/dev/null

  run ./bin/palari accept POS-0102 --by HUMAN-R2A
  [ "$status" -ne 0 ]
  [[ "$output" == *"authority_max_risk R2"* ]]

  run ./bin/palari accept POS-0102 --by HUMAN-R5A
  [ "$status" -eq 0 ]
  grep -Fq "acceptance_mode: human" tickets/closed/POS-0102-r5-accept-gate.md

  python3 - <<'PY'
from pathlib import Path
path = Path("palari.config.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace("    R5: 1", "    R5: 2", 1)
path.write_text(text, encoding="utf-8")
PY
  git add palari.config.yaml
  git commit -m "test R5 quorum two" >/dev/null

  ./bin/palari ticket create POS-0104 "R5 quorum two accept gate" \
    --stream process \
    --risk R5 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "true" >/dev/null
  ./bin/palari ticket claim POS-0104 implementer >/dev/null
  cat >reports/POS-0104-technical-report.md <<'DOC'
# POS-0104 Technical Report

## Files Changed

- `tickets/open/POS-0104-r5-quorum-two-accept-gate.md`

## Verification

- `true`

## CI Evidence

- `palari ci POS-0104`

## Risks / Follow-Ups

- Test fixture only.
DOC
  cat >reports/POS-0104-reviewer-note.md <<'DOC'
# POS-0104 Reviewer Note

## Review Result

Accept-ready fixture.

## Findings

No blocking findings.

## Verification Reviewed

- `palari ci POS-0104`

## Required Changes

None.

## Recommendation

Accept with two R5-authorized humans because the fixture config sets R5 quorum to 2.
DOC
  cat >reports/human/POS-0104-human-report.md <<'DOC'
# POS-0104 Human Report

## Why This Mattered

The configurable quorum must still enforce two distinct humans when R5 is set to 2.

## What Changed

Test-only fixture.

## What I Should Know

No production governance setting is changed by this fixture.

## What To Check

R5 accept refuses unsafe acceptor combinations and accepts two R5 humans when configured.

## Recommended Next Move

Keep configurable quorum enforcement active.
DOC

  ./bin/palari ci POS-0104 >/dev/null
  ./bin/palari ticket ready POS-0104 >/dev/null

  run ./bin/palari accept POS-0104 --by HUMAN-R5A
  [ "$status" -ne 0 ]
  [[ "$output" == *"R5 tickets require 2 human approval(s)"* ]]

  run ./bin/palari accept POS-0104 --by HUMAN-R5A --co-by HUMAN-R5A
  [ "$status" -ne 0 ]
  [[ "$output" == *"distinct humans"* ]]

  run ./bin/palari accept POS-0104 --by HUMAN-R5A --co-by HUMAN-R2A
  [ "$status" -ne 0 ]
  [[ "$output" == *"authority_max_risk R2"* ]]

  run ./bin/palari accept POS-0104 --by HUMAN-R5A --co-by HUMAN-R5B
  [ "$status" -eq 0 ]
  [[ "$output" == *"co-accepted-by: HUMAN-R5B"* ]]
  grep -Fq "co_accepted_by: HUMAN-R5B" tickets/closed/POS-0104-r5-quorum-two-accept-gate.md
  grep -Fq "acceptance_mode: human_dual" tickets/closed/POS-0104-r5-quorum-two-accept-gate.md
}
