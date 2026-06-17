# POS-0099 Technical Report

## Session

- Ticket: POS-0099
- Role: implementation
- Branch: ticket/POS-0099
- Target branch: main
- Result: implemented and ready for verification/review

## Files Changed

```text
README.md
contracts/adoption.md
lib/palari/init_adopt.bash
tests/run-adoption.sh
tickets/open/POS-0099-governed-bootstrap-adoption-lifecycle.md
reports/POS-0099-technical-report.md
reports/human/POS-0099-human-report.md
reports/evidence/POS-0099/
```

## Outcome

- Added `palari adopt plan TARGET --out FILE`.
- The generated plan records:
  - `type: bootstrap-adoption-plan`
  - `status: proposed`
  - source path
  - source SHA/ref when available
  - target path
  - target HEAD
  - CI/hooks/force intent
  - imported path manifest
  - excluded paths
  - excluded foreign governance artifacts
  - downstream customization boundaries
- Non-dry-run `palari adopt TARGET` now fails closed unless `--plan FILE` is
  provided.
- A plan must be `status: approved` or `status: accepted` before adoption writes
  target files.
- Adoption validates that the plan source and target match the current command.
- Adoption validates that the plan still includes foreign-governance-artifact
  exclusions.
- Dry-run adoption remains available without a plan as a no-write preview.
- README and the adoption contract now describe the preview -> plan -> human
  approval -> adopt flow.

## Verification

- Passed:
  - `bash -n lib/palari/init_adopt.bash tests/run-adoption.sh tests/run-cli-structure.sh`
  - `./tests/run-adoption.sh`
  - `./tests/run-cli-structure.sh`
  - `./tests/run-golden.sh`
  - `shellcheck -x bin/palari scripts/palari tests/run-adoption.sh`
  - `shfmt -d lib/palari/init_adopt.bash tests/run-adoption.sh`
  - `git diff --check`
- Added repair coverage after initial fresh review:
  - stale `source_sha` in an approved plan fails before writing.
  - missing `excluded_foreign_governance_artifacts` entries fail before
    writing.

## CI Evidence

- CI run: `./bin/palari ci POS-0099`
- Evidence bundle: `reports/evidence/POS-0099/`
- JUnit: `reports/evidence/POS-0099/junit.xml`
- SARIF: `reports/evidence/POS-0099/palari.sarif`
- Manifest: `reports/evidence/POS-0099/manifest.json`
- CI result: passed
- Initial strict evidence score: 85/100, `needs-review`, because the fresh
  reviewer note is not yet present.

## Boundaries

- Did not change secrets, dependencies, lockfiles, runtime state, deployment
  config, broker behavior, policy acceptance behavior, push, merge, or deploy
  behavior.
- Did not implement downstream artifact curation beyond recording excluded
  foreign governance artifacts in the plan. That is reserved for a later ticket.
- Did not change actor identity or acceptance authority behavior.

## Residual Risks

- The plan approval is a plain repo-native artifact check, not a cryptographic
  signature.
- Direct manual `rsync`/shell copying outside Palari cannot be prevented by the
  CLI; this ticket makes the Palari-supported adoption path governed and
  fail-closed.
- Initial fresh-context review found two low-severity bounded gaps: missing
  validation for `excluded_foreign_governance_artifacts` and no stale
  `source_sha` regression. Both were repaired before final review.

## Risks / Follow-Ups

- Follow-up ticket: downstream adoption boundary work should prevent upstream
  project history, reports, evidence, and self-tests from becoming active
  downstream governance by default.
- Follow-up ticket: stable actor identity should make the human approval record
  stronger than display-name strings.
