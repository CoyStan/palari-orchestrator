# POS-0091 Technical Report

## Session

- Ticket: POS-0091
- Role: implementation
- Branch: ticket/POS-0091
- Commit: pending
- Result: in-review

## Files Changed

```text
lib/palari/humans.bash
tests/run-human-governance.sh
tickets/open/POS-0091-add-migration-helper-for-human-capacity-fields.md
reports/POS-0091-technical-report.md
reports/POS-0091-reviewer-note.md
reports/human/POS-0091-human-report.md
reports/evidence/POS-0091/
```

## Outcome

- What changed: added `palari human migrate-capacity --check|--write`.
- `--check` reports human profiles that still carry deprecated `capacity_weekly_hgl`, `capacity_open_r3`, `capacity_open_r4`, or `capacity_open_r5` fields without modifying files.
- `--write` refuses a dirty repo before making changes, then migrates legacy capacity fields into `weekly_hgl_budget`, `current_weekly_hgl`, `max_concurrent_r3/r4/r5`, and `current_open_r3/r4/r5`.
- Migration removes deprecated capacity fields after writing the current operational fields.
- `human create` now writes only the current operational capacity fields for new profiles.
- Human lint remains compatible with legacy capacity fields so old profiles can be checked before migration.
- Focused tests cover check-mode no side effects, dirty-repo refusal, deterministic write output, lint compatibility before migration, and lint success after migration.
- What did not change: HGL scoring, workflow planning semantics, authority ceilings, R5 policy rules, policy simulation, broker behavior, dependencies, secrets, runtime state, deployment, and side effects did not change.
- Blockers: none.
- Next action: fresh-context review.

## Verification

- Passed:
  - `bash -n lib/palari/humans.bash tests/run-human-governance.sh`
  - `./bin/palari human lint`
  - `./bin/palari human migrate-capacity --check`
  - `./bin/palari human help`
  - `./tests/run-human-governance.sh`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-workflow-planning.sh`
  - `./bin/palari lint POS-0091`
  - `./bin/palari report-lint POS-0091`
  - `./bin/palari scope-check POS-0091`
  - `./bin/palari ci POS-0091`
- Failed during implementation:
  - Initial `./tests/run-human-governance.sh` runs exposed that write-mode correctly refused the dirty temp repo before the intended migration write. The test now commits its fixture baseline before testing write mode.
- Not run:
  - Full repository-wide test loop; POS-0091 is scoped to the human capacity migration helper and adjacent HGL/workflow planning coverage.

## CI Evidence

- CI run: `./bin/palari ci POS-0091`
- Evidence bundle: `reports/evidence/POS-0091/`
- JUnit: `reports/evidence/POS-0091/junit.xml`
- SARIF: `reports/evidence/POS-0091/palari.sarif`
- Attestation: `reports/evidence/POS-0091/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0091-reviewer-note.md`

## Risks / Follow-Ups

- The helper removes deprecated fields rather than preserving them as comments; human lint still supports old fields before migration.
- `--write` has no force flag. That keeps the migration conservative but means operators must commit or clear unrelated changes first.
- Existing runtime code still accepts legacy capacity fields as a compatibility fallback.
