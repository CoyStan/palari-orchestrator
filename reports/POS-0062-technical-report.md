# POS-0062 Technical Report

## Session

- Ticket: POS-0062
- Role: implementation
- Branch: ticket/POS-0062
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/planning/hgl.py
adapters/planning/workflow_plan.py
contracts/workflows.md
contracts/human-governance-load.md
lib/palari/workflows.bash
tests/run-workflows.sh
tests/run-workflow-planning.sh
tests/run-human-governance-load.sh
tickets/open/POS-0062-workflow-planning-uses-risk-ceiling-and-work-unit-risk.md
reports/POS-0062-technical-report.md
reports/POS-0062-reviewer-note.md
reports/human/POS-0062-human-report.md
reports/evidence/POS-0062/
```

## Outcome

- What changed: HGL and workflow planning now compute `risk_sources` from workflow risk ceiling, work-unit risks, and expected-decision risks. R5/R4 declared risk prevents high/full autonomy even when expected decisions are empty. Workflow lint now fails R4/R5 work units without expected decision coverage and warns for R3 work units without coverage or an exception.
- What did not change: POS-0062 does not add the fuller snapshot fields planned for POS-0064, does not change policy acceptance, broker behavior, external side effects, secrets, deployment, dependencies, or lockfiles.
- Blockers: none.
- Next action: fresh-context review, then founder/human acceptance if accept-ready.

## Verification

- Passed:
  - `bash -n lib/palari/workflows.bash`
  - `python3 -m py_compile adapters/planning/hgl.py adapters/planning/workflow_plan.py`
  - `./bin/palari workflow lint`
  - `./tests/run-workflows.sh`
  - `./tests/run-workflow-planning.sh`
  - `./tests/run-company-os-snapshot.sh`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-company-os-demo.sh`
  - `./bin/palari ci POS-0062`
- Failed:
  - Initial extra HGL sanity pass failed because the inherited POS-0060 test expected covered R5 to become `human_led`; POS-0062 intentionally makes R5 remain `simulation_only` unless the workflow is explicitly human-led. The test was updated in scope.
- Not run:
  - Phase-level broad loop; this ticket is the workflow risk-source slice.

## CI Evidence

- CI run: `./bin/palari ci POS-0062`
- Evidence bundle: `reports/evidence/POS-0062/`
- JUnit: `reports/evidence/POS-0062/junit.xml`
- SARIF: `reports/evidence/POS-0062/palari.sarif`
- Attestation: `reports/evidence/POS-0062/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0062-reviewer-note.md`

## Risks / Follow-Ups

- POS-0064 should expose fuller risk-source state in the company OS snapshot/dashboard; POS-0062 keeps snapshot behavior passing without broadening into the snapshot ticket.
- R3 missing decision coverage is currently a warning, matching the plan's recommended behavior. A later policy/schema ticket can make exception syntax stricter.
