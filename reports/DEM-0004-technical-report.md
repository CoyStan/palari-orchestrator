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

Pending.

## CI Evidence

Pending.

## Risks / Follow-Ups

- The demo creates local fixture artifacts in the working tree when run outside
  a temporary test repo; use `--force` to replace them deterministically.
- The policy candidate is simulation-only. No policy file is created or
  activated.
