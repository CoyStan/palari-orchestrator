# POS-0085 Technical Report

## Session

- Ticket: POS-0085
- Role: implementation
- Branch: ticket/POS-0085
- Commit: pending
- Result: in-review

## Files Changed

```text
lib/palari/demo.bash
tests/run-company-os-demo.sh
tickets/open/POS-0085-expand-company-os-demo-across-growth-support-and-engineering.md
reports/POS-0085-technical-report.md
reports/POS-0085-reviewer-note.md
reports/human/POS-0085-human-report.md
reports/evidence/POS-0085/
```

## Outcome

- What changed: `palari demo --company-os --force` now creates a multi-workflow company OS demo.
- Demo workflows:
  - Growth: yellow launch gate, `conditional_autonomy`, product governor bottleneck.
  - Support: green launch gate, `high_autonomy`, low-risk support pattern.
  - Engineering: red launch gate, `simulation_only`, missing active `privacy:L5` coverage.
- Demo humans now include founder/general manager, product/growth, technical/security, customer/brand, and a proposed privacy governor that is intentionally not active.
- Demo still creates a low-risk repeated decision policy candidate, one mock broker observation, and one recorded outcome.
- What did not change: HGL scoring, policy acceptance, broker permissions, real side effects, authority rules, dependencies, secrets, runtime state, deployment, and production behavior did not change.
- Blockers: none.
- Next action: fresh-context review.

## Verification

- Passed:
  - `bash -n lib/palari/demo.bash tests/run-company-os-demo.sh tests/run-company-os-snapshot.sh`
  - `./bin/palari demo --company-os --force`
  - `./tests/run-company-os-demo.sh`
  - `./tests/run-company-os-snapshot.sh`
- Failed:
  - none after implementation.
- Not run:
  - Full repository test loop; POS-0085 is scoped to the company OS demo fixture and focused demo/snapshot tests.

## CI Evidence

- CI run: `./bin/palari ci POS-0085`
- Evidence bundle: `reports/evidence/POS-0085/`
- JUnit: `reports/evidence/POS-0085/junit.xml`
- SARIF: `reports/evidence/POS-0085/palari.sarif`
- Attestation: `reports/evidence/POS-0085/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0085-reviewer-note.md`

## Risks / Follow-Ups

- Directly running the demo command writes fixture artifacts into the current repo by design. Tests run it in disposable copies; local direct verification artifacts were removed before commit.
- Future operator-view tickets can render this richer fixture set, but this ticket does not add dashboard UI.
