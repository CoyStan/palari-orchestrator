# POS-0081 Technical Report

## Session

- Ticket: POS-0081
- Role: implementation
- Branch: ticket/POS-0081
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/planning/hgl_calibration.py
lib/palari/burden.bash
contracts/human-governance-load.md
contracts/outcomes.md
tests/run-human-governance-load.sh
tests/run-outcomes.sh
tickets/open/POS-0081-add-hgl-calibration-report-from-outcomes.md
reports/POS-0081-technical-report.md
reports/POS-0081-reviewer-note.md
reports/human/POS-0081-human-report.md
reports/evidence/POS-0081/
```

## Outcome

- What changed: added `palari burden calibrate` and `palari burden calibrate --json`.
- The report reads recorded outcome impact fields and surfaces:
  - HGL overestimates.
  - HGL underestimates.
  - predicted-vs-actual risk mismatches.
  - successful policy-candidate decision classes.
  - evidence references associated with lower actual HGL.
- The report explicitly says it is read-only and encodes `weight_changes_applied: false` and `policy_changes_applied: false`.
- What did not change: HGL weights, scoring behavior, coverage rules, authority rules, policy activation, workflow state, human profiles, outcome lifecycle, broker behavior, external integrations, secrets, dependencies, runtime state, deployment, and side effects did not change.
- Blockers: none.
- Next action: fresh-context review.

## Verification

- Passed:
  - `python3 -m py_compile adapters/planning/hgl_calibration.py adapters/planning/hgl.py adapters/planning/policy_candidates.py`
  - `bash -n lib/palari/burden.bash tests/run-outcomes.sh tests/run-human-governance-load.sh`
  - `./bin/palari burden calibrate`
  - `./bin/palari burden calibrate --json`
  - `./tests/run-outcomes.sh`
  - `./tests/run-human-governance-load.sh`
- Failed:
  - none after implementation.
- Not run:
  - Full repository test loop; POS-0081 is scoped to HGL calibration reporting and focused outcome/HGL tests.

## CI Evidence

- CI run: `./bin/palari ci POS-0081`
- Evidence bundle: `reports/evidence/POS-0081/`
- JUnit: `reports/evidence/POS-0081/junit.xml`
- SARIF: `reports/evidence/POS-0081/palari.sarif`
- Attestation: `reports/evidence/POS-0081/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0081-reviewer-note.md`

## Risks / Follow-Ups

- Evidence pattern detection uses linked evidence file names as the first deterministic signal. Richer evidence-template taxonomy can be added later if Palari introduces explicit evidence template metadata.
- Calibration recommendations are intentionally conservative and require a future human-approved ticket before any HGL weight, risk, or policy change.
