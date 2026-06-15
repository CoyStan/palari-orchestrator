# DEM-0004 Technical Report

## Files Changed

- `lib/palari/demo.bash`
  - Adds `palari demo --company-os` and deterministic fixture helpers.
- `tests/run-company-os-demo.sh`
  - Covers fixture creation, force replacement, workflow plan, policy
    candidate output, broker evidence, snapshot, and web check.
- `tickets/open/DEM-0004-add-company-os-demo-fixtures.md`
  - Replaces the generated body with the scoped completion contract.
- `STATE.md`, `CHANGELOG.md`
  - Record the Company OS demo capability.

## Verification

Passed during implementation:

- `bash -n lib/palari/demo.bash`
- `./tests/run-demo.sh`
- `./tests/run-company-os-demo.sh`
- `./bin/palari demo --company-os --force >/tmp/palari-company-demo.out`
- `./bin/palari lint DEM-0004`
- `./bin/palari report-lint DEM-0004`
- `git diff --check`

## CI Evidence

Passed:

- `./bin/palari scope-check DEM-0004 --base ticket/SEC-0001`
- `./bin/palari ci DEM-0004 --base ticket/SEC-0001`
- `./bin/palari evidence score DEM-0004`

Evidence bundle:

- `reports/evidence/DEM-0004/verification.log`
- `reports/evidence/DEM-0004/junit.xml`
- `reports/evidence/DEM-0004/palari.sarif`
- `reports/evidence/DEM-0004/manifest.json`

Evidence quality score: 100/100, rating `ready`.

## Risks / Follow-Ups

- The demo creates local fixture artifacts in the working tree when run outside
  a temporary test repo; use `--force` to replace them deterministically.
- The policy candidate is simulation-only. No policy file is created or
  activated.
- CI's direct demo run produced deterministic local fixture artifacts, which
  were removed after verification so they are not committed as source state.
