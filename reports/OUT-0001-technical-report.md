# OUT-0001 Technical Report

## Files Changed

- `contracts/outcomes.md`
  - Defines the outcome ledger boundary.
- `templates/outcome.md`
  - Adds the outcome artifact template.
- `outcomes/open/.gitkeep`, `outcomes/recorded/.gitkeep`
  - Adds outcome queues.
- `lib/palari/core.bash`, `lib/palari/init_adopt.bash`,
  `palari.config.yaml`, `schemas/palari.config.schema.json`
  - Adds outcome directory config/default/init support.
- `lib/palari/outcomes.bash`, `bin/palari`
  - Adds `palari outcome create|list|show|lint|record`.
- `adapters/planning/policy_candidates.py`, `lib/palari/policies.bash`
  - Allows policy candidate suggestions to cite linked recorded outcomes.
- `tests/run-outcomes.sh`, `tests/run-policy-candidates.sh`
  - Cover outcome lifecycle and candidate outcome citation.
- `STATE.md`, `CHANGELOG.md`
  - Record the outcome ledger capability.
- `tickets/open/OUT-0001-add-outcome-ledger.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `bash -n lib/palari/outcomes.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_candidates.py`
- `./tests/run-outcomes.sh`
- `./tests/run-policy-candidates.sh`

## CI Evidence

Pending final `palari ci OUT-0001 --base ticket/BRK-0001`.

## Risks / Follow-Ups

- Outcomes are records, not proof of business impact unless evidence is linked.
- Outcome analytics, dashboard cards, and snapshot counts are out of scope.
- Policy candidates cite outcomes only as context; outcomes do not grant policy
  authority.
