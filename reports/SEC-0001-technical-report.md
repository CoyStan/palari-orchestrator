# SEC-0001 Technical Report

## Files Changed

- `lib/palari/init_adopt.bash`
  - Adds `palari doctor secure` and `palari doctor governance`.
- `bin/palari`
  - Updates command help for the new doctor subcommands.
- `palari.config.yaml`
  - Adds conservative governance posture defaults.
- `tests/run-secure-doctor.sh`
  - Covers weak posture, stronger local posture, R5 missing config, and
    branch-protection non-overclaim.
- `STATE.md`, `CHANGELOG.md`
  - Record the secure governance doctor capability.
- `tickets/open/SEC-0001-add-secure-governance-doctor.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `bash -n lib/palari/init_adopt.bash`
- `bash -n bin/palari`
- `./tests/run-secure-doctor.sh`
- `./tests/run-gate.sh`
- `./tests/run-gate-kernel.sh`
- `./bin/palari lint SEC-0001`
- `./bin/palari report-lint SEC-0001`
- `git diff --check`

## CI Evidence

Passed:

- `./bin/palari scope-check SEC-0001 --base ticket/OUT-0001`
- `./bin/palari ci SEC-0001 --base ticket/OUT-0001`
- `./bin/palari evidence score SEC-0001`

Evidence bundle:

- `reports/evidence/SEC-0001/verification.log`
- `reports/evidence/SEC-0001/junit.xml`
- `reports/evidence/SEC-0001/palari.sarif`
- `reports/evidence/SEC-0001/manifest.json`

Evidence quality score: 100/100, rating `ready`.

## Risks / Follow-Ups

- Hosted branch protection cannot be verified from this local doctor and is
  explicitly reported as not locally verified.
- This ticket does not enable ForgeGate, policy acceptance authority, real
  broker side effects, credentials, or hosted side effects.
