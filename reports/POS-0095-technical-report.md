# POS-0095 Technical Report

## Session

- Ticket: POS-0095
- Role: implementation
- Branch: ticket/POS-0095
- Commit: pending
- Result: in-review

## Files Changed

```text
contracts/adapters.md
tests/run-agent-wrapper.sh
tickets/open/POS-0095-define-company-os-worker-adapter-contract.md
reports/POS-0095-technical-report.md
reports/POS-0095-reviewer-note.md
reports/human/POS-0095-human-report.md
reports/evidence/POS-0095/
```

## Outcome

- What changed: added a Company OS Worker Adapter Contract to `contracts/adapters.md`.
- The contract covers future Hermes, GBrain, OpenRouter, Codex, local agents, and human delegates.
- The contract defines worker types: coding agent, research agent, review agent, memory provider, model provider, workflow executor, and human delegate.
- The contract says workers may receive scoped Palari work packets, produce outputs/logs/evidence, and request broker actions.
- The contract says workers must declare worker type, provider, model, runtime, version, and execution environment.
- The contract says workers must be auditable by Palari and treat repo-native artifacts as the authority source.
- The contract says workers must not hold company credentials directly, accept work, bypass gates, merge, deploy, send, charge, or refund unless a broker permits and records the action.
- Added focused `tests/run-agent-wrapper.sh` assertions so the key contract language cannot silently disappear.
- What did not change: no real worker integration, network dependency, credential path, hosted service, broker side effect, lifecycle behavior, policy acceptance, HGL scoring, R5 control, dependencies, secrets, deployment, or runtime state changed.
- Blockers: none.
- Next action: fresh-context review and human/founder review.

## Verification

- Passed:
  - `bash -n tests/run-agent-wrapper.sh`
  - `./tests/run-agent-wrapper.sh`
  - `./bin/palari lint POS-0095`
  - `./bin/palari report-lint POS-0095`
  - `./bin/palari scope-check POS-0095`
  - `./bin/palari ci POS-0095`
- Failed during implementation:
  - Initial wrapper test failed because one new grep assertion crossed a Markdown line wrap. The assertion was split into line-local checks.
- Not run:
  - Full repository-wide test loop; POS-0095 is scoped to contract language and the existing wrapper boundary test.

## CI Evidence

- CI run: `./bin/palari ci POS-0095`
- Evidence bundle: `reports/evidence/POS-0095/`
- JUnit: `reports/evidence/POS-0095/junit.xml`
- SARIF: `reports/evidence/POS-0095/palari.sarif`
- Attestation: `reports/evidence/POS-0095/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0095-reviewer-note.md`

## Risks / Follow-Ups

- This is a contract-only ticket. It deliberately does not prove a real external worker integration.
- Later integration tickets must bind actual worker adapters to broker evidence, credential isolation, and R5/human authority gates before side effects are considered.
