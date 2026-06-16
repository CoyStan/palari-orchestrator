# POS-0090 Technical Report

## Session

- Ticket: POS-0090
- Role: implementation
- Branch: ticket/POS-0090
- Commit: pending
- Result: in-review

## Files Changed

```text
contracts/company-ai-os.md
schemas/workflow.schema.json
schemas/human.schema.json
schemas/policy.schema.json
schemas/outcome.schema.json
schemas/broker-observation.schema.json
schemas/company-os-snapshot.schema.json
tests/run-company-os-schemas.sh
tickets/open/POS-0090-add-schemas-for-company-os-artifacts.md
reports/POS-0090-technical-report.md
reports/POS-0090-reviewer-note.md
reports/human/POS-0090-human-report.md
reports/evidence/POS-0090/
```

## Outcome

- What changed: added typed JSON Schema contracts for workflow, human governance profile, simulation policy, outcome, broker observation, and the company OS snapshot section.
- The schemas document current frontmatter/snapshot fields plus compatibility fields that already exist in the repo-native artifacts.
- The policy schema keeps policy mode simulation-only and restricts `risk_max` to R0/R1/R2.
- The broker observation schema requires `side_effects_enabled`, credential access, and hosted/network access to remain false for the current mock/sandbox boundary.
- The company OS snapshot schema requires truthful top-level governance sections and keeps `policy.simulation_only: true` and `broker.real_side_effects_enabled: false`.
- Added `tests/run-company-os-schemas.sh`, which creates representative artifacts in a temporary repo, runs existing lints, parses frontmatter with stdlib-only code, validates the fixtures against the new schemas, and uses `jsonschema` too when available.
- Updated `contracts/company-ai-os.md` to describe the typed-schema compatibility boundary.
- What did not change: runtime parsers, workflow lifecycle, human governance behavior, HGL scoring, policy acceptance, broker behavior, authority rules, secrets, dependencies, deployment, runtime state, and side effects did not change.
- Blockers: none.
- Next action: fresh-context review.

## Verification

- Passed:
  - `python3 -m json.tool` on the six new schema files
  - `bash -n tests/run-company-os-schemas.sh`
  - `./bin/palari workflow lint`
  - `./bin/palari human lint`
  - `./bin/palari policy lint`
  - `./bin/palari outcome lint`
  - `./tests/run-company-os-schemas.sh`
  - `./bin/palari lint POS-0090`
  - `./bin/palari report-lint POS-0090`
  - `./bin/palari scope-check POS-0090`
  - `./bin/palari ci POS-0090`
- Failed during implementation:
  - Initial schema fixture runs exposed fixture-only issues: stale broker ID, positional `outcome create` title usage, and over-escaped frontmatter parser regexes. These were corrected in the focused test script.
- Not run:
  - Full repository-wide test loop; POS-0090 is scoped to schema contracts and representative schema fixture validation.

## CI Evidence

- CI run: `./bin/palari ci POS-0090`
- Evidence bundle: `reports/evidence/POS-0090/`
- JUnit: `reports/evidence/POS-0090/junit.xml`
- SARIF: `reports/evidence/POS-0090/palari.sarif`
- Attestation: `reports/evidence/POS-0090/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0090-reviewer-note.md`

## Risks / Follow-Ups

- The schemas are documentation and test contracts in this ticket; runtime lint remains Bash/Python.
- The stdlib validator intentionally covers the JSON Schema features used by these schema files and representative fixtures, not a full JSON Schema implementation. When `jsonschema` is installed, the test also runs full JSON Schema validation.
- POS-0091 should add the planned human capacity migration helper rather than hiding old/new capacity compatibility inside these schemas.
