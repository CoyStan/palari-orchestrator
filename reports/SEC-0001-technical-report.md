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

Pending.

## CI Evidence

Pending.

## Risks / Follow-Ups

- Hosted branch protection cannot be verified from this local doctor and is
  explicitly reported as not locally verified.
- This ticket does not enable ForgeGate, policy acceptance authority, real
  broker side effects, credentials, or hosted side effects.
