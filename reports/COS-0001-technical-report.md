# COS-0001 Technical Report

## Files Changed

- `lib/palari/core.bash`
  - Added `R5` to `VALID_RISKS`.
- `lib/palari/tickets_workspace.bash`
  - Makes R5 ticket creation set `requires_review: true`,
    `requires_human_confirmation: true`, and the heavier completion contract.
- `lib/palari/agents_review_scope.bash`
  - Extends report-lint review/technical/human gates to include R5.
- `lib/palari/dashboard_snapshot.bash`
  - Extends fast readiness checks so R5 is treated as review- and human-gated.
- `lib/palari/evidence_quality.bash`
  - Extends evidence score review and human/founder gates to include R5.
- `lib/palari/models.bash`
  - Adds `model_class_r5` and shows R5 in `palari model routes`.
- `lib/palari/roles.bash`
  - Adds R5 to role risk ranking above R4.
- `palari.config.yaml` and `schemas/palari.config.schema.json`
  - Add `model_class_r5`, defaulting to `frontier`.
- `roles/active/ROLE-ROOT.md`
  - Raises root authority max risk to R5.
- `README.md`, `contracts/company-ai-os.md`, `STATE.md`, `CHANGELOG.md`
  - Document R5 as governance/kernel/authority risk.
- `tests/run-risks.sh`
  - Adds focused R5 coverage.
- `tests/run-model-routing.sh`
  - Adds R5 routing coverage.
- `tickets/open/COS-0001-add-r5-governance-risk-tier.md`
  - Tracks this scoped governance-risk slice.

## Verification

Passed:

- `./tests/run-risks.sh`
- `./tests/run-cli-structure.sh`
- `./tests/run-roles.sh`
- `./tests/run-model-routing.sh`
- `./tests/run-state.sh`
- `./bin/palari lint COS-0001`
- `./bin/palari report-lint COS-0001`
- `./bin/palari scope-check COS-0001`
- `git diff --check`

## CI Evidence

Pending local `palari ci COS-0001 --base ticket/COS-0000` evidence bundle.

## Risks / Follow-Ups

- R5 is now valid and gated, but this ticket does not implement policy
  simulation, broker behavior, dual-human R5 acceptance, or secure doctor
  posture checks. Those remain later roadmap slices.
- The root role can now express R5 authority. That does not grant agents
  acceptance authority; ticket/report/evidence/human gates still apply.
