# POS-0077 Technical Report

## Session

- Ticket: POS-0077
- Role: implementation
- Branch: ticket/POS-0077
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/planning/governance_debt.py
adapters/planning/company_os_snapshot.py
lib/palari/burden.bash
contracts/human-governance-load.md
tests/run-human-governance-load.sh
tests/run-company-os-snapshot.sh
tickets/open/POS-0077-add-human-governance-debt-report.md
reports/POS-0077-technical-report.md
reports/POS-0077-reviewer-note.md
reports/human/POS-0077-human-report.md
reports/evidence/POS-0077/
```

## Outcome

- What changed: Added `palari burden debt [--json]`, backed by `adapters/planning/governance_debt.py`.
- The debt report summarizes missing skill coverage, high-risk bottlenecks, capacity pressure, weak evidence, configured R5 human-quorum coverage gaps, and low-risk policy-candidate opportunities from current repo-native artifacts.
- Company OS snapshot now includes `company_os.human_governance.debt` with level, item count, and highest-leverage fix.
- What did not change: HGL scoring, launch gates, authority semantics, policy acceptance, broker behavior, workflows, humans, outcomes, secrets, dependencies, runtime state, deployment, and side effects were not changed.
- Blockers: none.
- Next action: fresh-context review, then continue to POS-0078 if accept-ready.

## Verification

- Passed:
  - `python3 -m py_compile adapters/planning/governance_debt.py adapters/planning/company_os_snapshot.py adapters/planning/hgl.py adapters/planning/policy_candidates.py`
  - `./bin/palari burden debt`
  - `./bin/palari burden debt --json`
  - `./bin/palari snapshot --json`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-company-os-snapshot.sh`
- Failed:
  - Initial smoke failed because the Bash wrapper used non-existent `TICKETS_OPEN_DIR`/`TICKETS_CLOSED_DIR` globals. Fixed to use existing `OPEN_DIR`/`CLOSED_DIR`.
- Not run:
  - Full repository test loop; POS-0077 is scoped to governance debt reporting and snapshot reference.

## CI Evidence

- CI run: `./bin/palari ci POS-0077`
- Evidence bundle: `reports/evidence/POS-0077/`
- JUnit: `reports/evidence/POS-0077/junit.xml`
- SARIF: `reports/evidence/POS-0077/palari.sarif`
- Attestation: `reports/evidence/POS-0077/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0077-reviewer-note.md`

## Risks / Follow-Ups

- The report is conservative and deterministic. It is not a complete staffing model.
- Some debt categories depend on existing artifact history. For example, policy-candidate debt only appears when the current policy candidate analyzer emits candidates.
- HGL calibration remains out of scope for POS-0077 and belongs to POS-0081.
