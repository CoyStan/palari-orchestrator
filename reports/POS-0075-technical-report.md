# POS-0075 Technical Report

## Session

- Ticket: POS-0075
- Role: implementation
- Branch: ticket/POS-0075
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/planning/artifacts.py
adapters/planning/company_os_snapshot.py
adapters/planning/hgl.py
adapters/planning/policy_candidates.py
adapters/planning/policy_simulation.py
tickets/open/POS-0075-centralize-company-os-artifact-parsing.md
reports/POS-0075-technical-report.md
reports/POS-0075-reviewer-note.md
reports/human/POS-0075-human-report.md
reports/evidence/POS-0075/
```

## Outcome

- What changed: Added `adapters/planning/artifacts.py` with shared frontmatter parsing, Markdown file discovery, artifact lookup, risk/level helpers, skill parsing, risk comparison, and pipe-record padding. HGL, policy simulation, policy candidates, and company OS snapshot now use those shared helpers instead of duplicate parsers.
- What did not change: No workflow, HGL, policy simulation, policy candidate, broker, acceptance, deployment, secret, dependency, or runtime behavior was intentionally changed.
- Blockers: none.
- Next action: fresh-context review, then POS-0076 can add a human decision map to workflow planning if accept-ready.

## Verification

- Passed:
  - `python3 -m py_compile adapters/planning/artifacts.py adapters/planning/hgl.py adapters/planning/workflow_plan.py adapters/planning/policy_simulation.py adapters/planning/policy_candidates.py adapters/planning/company_os_snapshot.py`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-workflow-planning.sh`
  - `./tests/run-policy-simulation.sh`
  - `./tests/run-policy-candidates.sh`
  - `./tests/run-company-os-snapshot.sh`
  - `./bin/palari lint POS-0075`
  - `./bin/palari report-lint POS-0075`
  - `./bin/palari scope-check POS-0075`
  - `./bin/palari ci POS-0075`
- Failed:
  - none after implementation.
- Not run:
  - Full repository test loop; POS-0075 is scoped to planning parser refactor.

## CI Evidence

- CI run: `./bin/palari ci POS-0075`
- Evidence bundle: `reports/evidence/POS-0075/`
- JUnit: `reports/evidence/POS-0075/junit.xml`
- SARIF: `reports/evidence/POS-0075/palari.sarif`
- Attestation: `reports/evidence/POS-0075/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0075-reviewer-note.md`

## Risks / Follow-Ups

- `policy_candidates.find_by_id` remains as a tiny compatibility wrapper around the shared lookup helper.
- The shared parser intentionally preserves the existing simple frontmatter behavior. It does not introduce a new YAML dependency.
- `risk_lte` now fails closed for invalid left or right risk values, matching the intended conservative behavior from earlier policy tickets.
