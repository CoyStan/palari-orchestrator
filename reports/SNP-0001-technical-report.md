# SNP-0001 Technical Report

## Files Changed

- `adapters/planning/company_os_snapshot.py`
  - Adds a shared stdlib Company OS snapshot builder used by both snapshot
    engines.
  - Counts workflow and human artifact state, scores active workflow HGL, and
    returns missing skills, bottlenecks, autonomy distribution, policy posture,
    and broker posture.
- `adapters/snapshot/fast_snapshot.py`
  - Imports the shared builder and adds top-level `company_os` output to the
    fast snapshot/web-check read model.
- `lib/palari/adapters_snapshot.bash`
  - Adds the same top-level `company_os` key to the Bash snapshot fallback.
- `tests/run-company-os-snapshot.sh`
  - Covers fast snapshot, Bash fallback, and web-check with populated
    workflow/human fixtures.
- `tests/run-dashboard-rubric.sh`
  - Extends the existing snapshot contract assertion to require the new
    top-level section.
- `STATE.md`, `CHANGELOG.md`
  - Record the shipped snapshot visibility capability.
- `tickets/open/SNP-0001-expose-company-os-state-in-snapshot.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `./tests/run-company-os-snapshot.sh`
- `./tests/run-performance.sh`
- `./tests/run-dashboard-rubric.sh`
- Fast snapshot manual check: `./bin/palari snapshot --json`
- Bash fallback manual check: `PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json`

## CI Evidence

Passed:

- `./bin/palari lint SNP-0001`
- `./bin/palari report-lint SNP-0001`
- `./bin/palari scope-check SNP-0001`
- `git diff --check`
- `./bin/palari ci SNP-0001 --base ticket/PLN-0001`
- `./bin/palari evidence score SNP-0001`

Evidence bundle:

- `reports/evidence/SNP-0001/verification.log`
- `reports/evidence/SNP-0001/junit.xml`
- `reports/evidence/SNP-0001/palari.sarif`
- `reports/evidence/SNP-0001/manifest.json`

Evidence quality score: 100/100, rating `ready`.

## Risks / Follow-Ups

- The snapshot section is compact by design. Rich dashboard cards belong to
  DSH-0001.
- Policy and broker values are posture fields only: simulation-only policy and
  real side effects disabled. Policy simulation and broker evidence remain
  future tickets.
- Fast snapshot imports the stdlib company OS builder and stays under existing
  performance thresholds in the current repo.
