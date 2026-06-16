# POS-0091 Reviewer Note

## Review Result

Accept-ready after bounded repair re-review.

## Findings

None in the 2026-06-16 repair re-review.

## Prior Review Findings Preserved

1. P1: migration can change HGL/workflow semantics for legacy zero risk-capacity fields.

   `lib/palari/humans.bash` copies legacy `capacity_open_r3`, `capacity_open_r4`, and `capacity_open_r5` values literally into `max_concurrent_r3`, `max_concurrent_r4`, and `max_concurrent_r5`. Existing HGL compatibility treats legacy zero values as unspecified and clamps them to at least 1, so old profiles created with `capacity_open_rN: 0` can become newly at-capacity after migration. The reviewer reproduced coverage changing from `covered_by=['HUMAN-LEGACY']` with no risk-capacity failures before migration to no coverage, `HUMAN-LEGACY at R4 capacity`, and a `yellow -> red` launch gate after migration.

2. P2: empty deprecated capacity keys are not detected or removed.

   The migration detects deprecated fields through non-empty `frontmatter_value` output. A profile containing empty keys such as `capacity_weekly_hgl:` or `capacity_open_r3:` can report `ok (no deprecated capacity fields found)`, and write mode leaves those deprecated keys in place.

## Verification Reviewed

- 2026-06-16 repair re-review inspected:
  - `lib/palari/humans.bash`
  - `tests/run-human-governance.sh`
  - `adapters/planning/hgl.py` legacy compatibility semantics
  - `reports/evidence/POS-0091/`
- 2026-06-16 repair checks:
  - `bash -n lib/palari/humans.bash tests/run-human-governance.sh`
  - `./tests/run-human-governance.sh`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-workflow-planning.sh`
  - `./bin/palari ci POS-0091`
  - `./bin/palari evidence score POS-0091 --strict`
  - `./bin/palari scope-check POS-0091`
  - `./bin/palari report-lint POS-0091`
- Independent repair re-review result:
  - Accept-ready.
  - No blocking or non-blocking findings.
  - Confirmed legacy zero `capacity_open_rN` values migrate to HGL-compatible nonzero `max_concurrent_rN` behavior.
  - Confirmed empty deprecated keys are detected by key presence and removed/migrated by write mode.
  - Confirmed changed-path scan found no dependencies, lockfiles, deployment files, secret/env paths, broker surfaces, or unrelated runtime state.
- Prior review inspected:
- `./tests/run-human-governance.sh`
- `./bin/palari human lint`
- `./tests/run-human-governance-load.sh`
- `./tests/run-workflow-planning.sh`
- `bash -n lib/palari/humans.bash tests/run-human-governance.sh`
- `./bin/palari human migrate-capacity --check`
- `git diff --check 889abff^ 889abff -- lib/palari/humans.bash tests/run-human-governance.sh`
- Two isolated temp-repo repro scripts for legacy-zero migration and empty-key detection.

## Required Changes

- Complete. Preserve legacy HGL semantics when migrating zero/unspecified risk capacity fields.
- Complete. Detect deprecated capacity keys by key presence, not only non-empty value.
- Complete. Add regression tests for both cases.
- Complete. Rerun focused human-governance, HGL load, workflow planning, ticket/report/scope/evidence checks, then run fresh-context re-review again.

## Recommendation

POS-0091 is ready for founder acceptance. Do not accept without explicit founder approval.

## Evidence Notes

- Regression coverage now exercises the two reviewer repro cases.
- Residual risk is low: the before/after regression compares the important HGL burden-score behavioral fields instead of the entire JSON payload, and the migration defaults were checked against the HGL adapter's documented legacy parsing semantics.
