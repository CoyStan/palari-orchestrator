# POS-0097 Technical Report

## Session

- Ticket: POS-0097
- Role: implementation
- Branch: ticket/POS-0097
- Commit: pending
- Result: in-review

## Files Changed

```text
contracts/adapters.md
tests/run-model-routing.sh
tests/run-openrouter.sh
tickets/open/POS-0097-define-governed-model-provider-contract.md
reports/POS-0097-technical-report.md
reports/POS-0097-reviewer-note.md
reports/human/POS-0097-human-report.md
reports/evidence/POS-0097/
```

## Outcome

- What changed: added a Governed Model Provider Contract to `contracts/adapters.md`.
- The contract says model providers are model capability suppliers, not authority layers.
- The contract says Palari controls routing policy and that routing is subordinate to ticket scope, risk tier, policy simulation posture, broker boundary, data classification, human governance, R5 controls, evidence requirements, and review/acceptance gates.
- The contract covers routing factors from the plan: risk, data sensitivity, cost, latency, task type, historical success, allowed providers, customer data restrictions, evaluation score, and fallback availability.
- The contract says model providers must declare provider/model/runtime/tool-use identity and make routing inputs, model identity, and returned content auditable through Palari evidence.
- The contract says model providers must not accept work, decide authority, decide policy, bypass gates, hold company credentials directly, hide provider/runtime identity, or replace human/fresh-context review.
- The contract says OpenRouter remains model supply, not governance.
- Added focused assertions to `tests/run-model-routing.sh` and `tests/run-openrouter.sh` so the key model-provider authority boundary cannot silently disappear.
- What did not change: no live model provider behavior, OpenRouter runtime behavior, routing runtime behavior, network call, credential path, dependency, lockfile, broker behavior, policy acceptance, HGL scoring, R5 control, ticket lifecycle, deployment, secrets, or runtime state changed.
- Blockers: none.
- Next action: fresh-context review and human/founder review.

## Verification

- Passed:
  - `bash -n tests/run-model-routing.sh tests/run-openrouter.sh`
  - `./tests/run-model-routing.sh`
  - `./tests/run-openrouter.sh`
  - `./bin/palari lint POS-0097`
  - `./bin/palari report-lint POS-0097`
  - `./bin/palari scope-check POS-0097`
  - `./bin/palari ci POS-0097`
- Failed:
  - None.
- Not run:
  - Full repository-wide test loop; POS-0097 is scoped to contract language and existing model/OpenRouter boundary tests.

## CI Evidence

- CI run: `./bin/palari ci POS-0097`
- Evidence bundle: `reports/evidence/POS-0097/`
- JUnit: `reports/evidence/POS-0097/junit.xml`
- SARIF: `reports/evidence/POS-0097/palari.sarif`
- Attestation: `reports/evidence/POS-0097/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0097-reviewer-note.md`

## Risks / Follow-Ups

- This is a contract-only ticket. It deliberately does not prove a live model provider governance implementation.
- Later model routing/provider tickets must bind runtime routing decisions to Palari policy, data-class, broker, human-governance, R5, review, and evidence controls.
