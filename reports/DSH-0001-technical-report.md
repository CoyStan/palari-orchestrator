# DSH-0001 Technical Report

## Files Changed

- `adapters/web/static/index.html`
  - Adds the Company Governance support panel.
- `adapters/web/static/app.js`
  - Adds `renderCompanyGovernance`, compact metric rendering, workflow gate
    pills, and render lifecycle wiring.
- `adapters/web/static/app-shell.css`
  - Adds compact metric and workflow-row styling for the new panel.
- `tests/run-dashboard-rubric.sh`
  - Adds structure/style/renderer assertions for the Company Governance panel.
- `STATE.md`, `CHANGELOG.md`
  - Record the shipped console visibility capability.
- `tickets/open/DSH-0001-add-company-governance-cards-to-console.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `node --check adapters/web/static/app.js`
- `./tests/run-dashboard-rubric.sh`
- `./bin/palari web --check >/tmp/palari-web-check.json`
- `git diff --check`

## CI Evidence

Passed:

- `./bin/palari lint DSH-0001`
- `./bin/palari report-lint DSH-0001`
- `./bin/palari scope-check DSH-0001`
- `./bin/palari ci DSH-0001 --base ticket/SNP-0001`
- `./bin/palari evidence score DSH-0001`

Evidence bundle:

- `reports/evidence/DSH-0001/verification.log`
- `reports/evidence/DSH-0001/junit.xml`
- `reports/evidence/DSH-0001/palari.sarif`
- `reports/evidence/DSH-0001/manifest.json`

Evidence quality score: 100/100, rating `ready`.

## Risks / Follow-Ups

- The panel is intentionally read-only and compact. It does not add new
  console controls for policy, broker, acceptance, merge, push, or deploy.
- The panel depends on SNP-0001's `company_os` snapshot contract.
- Richer workflow interaction or visualizations should wait for later tickets.
