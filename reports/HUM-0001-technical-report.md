# HUM-0001 Technical Report

## Files Changed

- `lib/palari/humans.bash`
  - Adds human profile ID validation, create/list/show/lint/adopt/revoke
    commands, and lint rules for skills, capacity, authority, and R5 policy
    approval.
- `bin/palari`
  - Sources the human module, advertises human commands, and dispatches
    `palari human`.
- `lib/palari/core.bash`
  - Adds human governance directory globals and includes `humans` in adoption
    paths.
- `lib/palari/init_adopt.bash`
  - Ensures human governance directories exist during init and checks the
    module in doctor.
- `palari.config.yaml` and `schemas/palari.config.schema.json`
  - Add human governance directory config keys.
- `contracts/human-governance.md`
  - Documents human governance profiles, fields, CLI, and non-authority
    boundary.
- `templates/human-profile.md`
  - Adds a human profile body template.
- `humans/proposed/.gitkeep`, `humans/active/.gitkeep`,
  `humans/revoked/.gitkeep`
  - Add the human governance state directories.
- `tests/run-human-governance.sh`
  - Covers create/list/show/lint/adopt/revoke and lint failures.
- `tests/run-cli-structure.sh`
  - Adds `humans` to the required module list.
- `README.md`, `STATE.md`, `CHANGELOG.md`
  - Document the new human governance artifact family and commands.
- `tickets/open/HUM-0001-add-human-governance-ledger.md`
  - Tracks this scoped human-governance slice.

## Verification

Passed:

- `./tests/run-human-governance.sh`
- `./tests/run-cli-structure.sh`
- `./tests/run-state.sh`
- `./bin/palari lint HUM-0001`
- `./bin/palari report-lint HUM-0001`
- `./bin/palari scope-check HUM-0001`
- `git diff --check`

## CI Evidence

Passed with `./bin/palari ci HUM-0001 --base ticket/WFU-0001`.

Evidence bundle:

- `reports/evidence/HUM-0001/verification.log`
- `reports/evidence/HUM-0001/junit.xml`
- `reports/evidence/HUM-0001/palari.sarif`
- `reports/evidence/HUM-0001/manifest.json`

## Risks / Follow-Ups

- Profiles do not score HGL or determine coverage yet. HGL scoring and human
  coverage are the next roadmap slice.
- Profiles are governance artifacts, not agent authority, HR records, or
  productivity surveillance.
