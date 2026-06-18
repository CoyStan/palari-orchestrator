# POS-0105 Technical Report

## Files Changed

- `README.md`
- `contracts/adoption.md`
- `lib/palari/init_adopt.bash`
- `tests/run-adoption.sh`
- `tickets/open/POS-0105-downstream-adoption-boundaries.md`

## Verification

- `bash -n lib/palari/init_adopt.bash tests/run-adoption.sh`
- `shfmt -d lib/palari/init_adopt.bash tests/run-adoption.sh`
- `./tests/run-adoption.sh`
- `./tests/run-cli-structure.sh`

## CI Evidence

- `reports/evidence/POS-0105/manifest.json`
- `reports/evidence/POS-0105/verification.log`
- `reports/evidence/POS-0105/junit.xml`
- `reports/evidence/POS-0105/palari.sarif`

## Risks / Follow-Ups

- Adoption now treats source governance-history directories as excluded input:
  tickets, reports, evidence, human reports, memory, tests, humans, workflows,
  policies, outcomes, goals, decisions, and handoffs are not copied as active
  downstream records.
- The adoption plan names the excluded upstream-owned governance artifacts, and
  adoption validates that list before non-dry-run writes.
- The path manifest and source manifest hash skip excluded governance-history
  paths so plan approval tracks the Palari substrate, not source project
  history.
- Target governance directories are still created by `palari init` as empty
  `.gitkeep` scaffolding.
- `lib/palari/init_adopt.bash` remains at the 1000-line CLI structure ceiling;
  future adoption changes should split helpers before adding new behavior.
