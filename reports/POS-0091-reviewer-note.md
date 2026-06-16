# POS-0091 Reviewer Note

## Review Result

Not accept-ready. Reopen for bounded migration repair.

## Findings

1. P1: migration can change HGL/workflow semantics for legacy zero risk-capacity fields.

   `lib/palari/humans.bash` copies legacy `capacity_open_r3`, `capacity_open_r4`, and `capacity_open_r5` values literally into `max_concurrent_r3`, `max_concurrent_r4`, and `max_concurrent_r5`. Existing HGL compatibility treats legacy zero values as unspecified and clamps them to at least 1, so old profiles created with `capacity_open_rN: 0` can become newly at-capacity after migration. The reviewer reproduced coverage changing from `covered_by=['HUMAN-LEGACY']` with no risk-capacity failures before migration to no coverage, `HUMAN-LEGACY at R4 capacity`, and a `yellow -> red` launch gate after migration.

2. P2: empty deprecated capacity keys are not detected or removed.

   The migration detects deprecated fields through non-empty `frontmatter_value` output. A profile containing empty keys such as `capacity_weekly_hgl:` or `capacity_open_r3:` can report `ok (no deprecated capacity fields found)`, and write mode leaves those deprecated keys in place.

## Verification Reviewed

- `./tests/run-human-governance.sh`
- `./bin/palari human lint`
- `./tests/run-human-governance-load.sh`
- `./tests/run-workflow-planning.sh`
- `bash -n lib/palari/humans.bash tests/run-human-governance.sh`
- `./bin/palari human migrate-capacity --check`
- `git diff --check 889abff^ 889abff -- lib/palari/humans.bash tests/run-human-governance.sh`
- Two isolated temp-repo repro scripts for legacy-zero migration and empty-key detection.

## Required Changes

- Preserve legacy HGL semantics when migrating zero/unspecified risk capacity fields.
- Detect deprecated capacity keys by key presence, not only non-empty value.
- Add regression tests for both cases.
- Rerun focused human-governance, HGL load, workflow planning, ticket/report/scope/evidence checks, then run fresh-context re-review again.

## Recommendation

Do not accept POS-0091. Reopen or repair before founder acceptance.

## Evidence Notes

- Existing focused tests pass, but they do not cover the two reviewer repro cases.
