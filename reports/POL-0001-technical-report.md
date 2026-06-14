# POL-0001 Technical Report

## Files Changed

- `contracts/policy-acceptance.md`
  - Adds the simulation-only policy acceptance contract.
- `templates/policy.md`
  - Adds a starter policy artifact template.
- `policies/proposed/.gitkeep`, `policies/active/.gitkeep`,
  `policies/revoked/.gitkeep`
  - Adds the policy artifact queues.
- `lib/palari/core.bash`, `lib/palari/init_adopt.bash`,
  `palari.config.yaml`, `schemas/palari.config.schema.json`
  - Adds configurable policy directory keys and init/adoption support.
- `lib/palari/policies.bash`, `bin/palari`
  - Adds `palari policy create|list|show|lint|simulate`.
- `adapters/planning/policy_simulation.py`
  - Adds the read-only simulation engine.
- `tests/run-policy-simulation.sh`
  - Covers policy create/list/show/lint, would-accept, would-not-accept,
    R5 refusal, unknown-condition fail-closed behavior, read-only simulation,
    and the absence of policy acceptance.
- `STATE.md`, `CHANGELOG.md`
  - Record the shipped policy simulation capability.
- `tickets/open/POL-0001-add-policy-artifacts-and-simulation-cli.md`
  - Replaces the generated body with the scoped completion contract and adds
    config/schema paths required by the roadmap's config-key requirement.

## Verification

Passed during implementation:

- `bash -n lib/palari/policies.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_simulation.py`
- `./tests/run-policy-simulation.sh`
- `./tests/run-evidence-quality.sh`

## CI Evidence

Pending final `palari ci POL-0001 --base ticket/DSH-0001`.

## Risks / Follow-Ups

- Policy acceptance remains simulation-only. No command can accept by policy.
- Policy activation lifecycle and candidate detection are intentionally out of
  scope for later tickets.
- The simulator mirrors Palari evidence scoring conservatively, but future
  policy work should avoid treating this first-pass scoring as a security
  boundary.
- Unknown conditions are lintable for drafting but fail closed in simulation.
