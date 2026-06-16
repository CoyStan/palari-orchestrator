# POS-0087 Technical Report

## Session

- Ticket: POS-0087
- Role: implementation
- Branch: ticket/POS-0087
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/snapshot/fast_snapshot.py
adapters/web/static/index.html
adapters/web/static/app.js
adapters/web/static/app-shell.css
lib/palari/adapters_snapshot.bash
tests/run-dashboard-rubric.sh
tests/run-company-os-snapshot.sh
tickets/open/POS-0087-dashboard-exposes-company-os-governance-cards.md
reports/POS-0087-technical-report.md
reports/POS-0087-reviewer-note.md
reports/human/POS-0087-human-report.md
reports/evidence/POS-0087/
```

## Outcome

- What changed: added additive `company_os.dashboard_cards` data to the fast/web snapshot.
- The dashboard cards cover Human Governance Load, R3/R4/R5 decisions, missing skills, bottlenecks, autonomy gates, policy candidates, broker posture, outcomes, secure posture, and active workflows.
- The web dashboard now renders those cards inside the existing Company Governance panel.
- Broker posture is explicitly labeled `mock / observed-only` unless real side effects are reported.
- Policy posture is explicitly labeled as simulation-only in the policy card detail.
- Red/yellow autonomy and governance states are encoded as card statuses and styled in the dashboard.
- Focused tests now require the card container, CSS, renderer, JSON shape, required card IDs, and explicit broker/policy labels.
- Verification repair: `./tests/run-dashboard-rubric.sh` exposed a legacy full-snapshot failure where overlap JSON was passed to `awk` as one oversized command argument. It now streams JSON into `awk`.
- Verification repair: legacy full snapshots now use the existing fast ticket-row serializer while still including accepted tickets in full mode. This avoids per-ticket deep report lint during snapshot rendering and keeps the required dashboard rubric practical on the stacked worktree.
- What did not change: workflow lifecycle, HGL scoring, policy acceptance, broker behavior, outcome state, authority rules, dependencies, secrets, runtime state, deployment, and side effects did not change.
- Blockers: none.
- Next action: fresh-context review.

## Verification

- Passed:
  - `python3 -m py_compile adapters/snapshot/fast_snapshot.py adapters/planning/company_os_snapshot.py`
  - `bash -n lib/palari/adapters_snapshot.bash tests/run-dashboard-rubric.sh tests/run-company-os-snapshot.sh`
  - `./bin/palari web --check`
  - `./tests/run-dashboard-rubric.sh`
  - `./tests/run-company-os-snapshot.sh`
- Failed during implementation:
  - Initial `./tests/run-dashboard-rubric.sh` failed with `/usr/bin/awk: Argument list too long` in `lib/palari/adapters_snapshot.bash`; fixed by streaming overlap JSON.
  - A direct `timeout 60s ./bin/palari snapshot --json --full` timed out before the ticket serializer optimization; fixed by using the existing fast ticket-row serializer for full snapshot ticket arrays.
- Not run:
  - Full repository-wide test loop; POS-0087 is scoped to dashboard/snapshot surfaces and the focused dashboard/company OS checks.

## CI Evidence

- CI run: `./bin/palari ci POS-0087`
- Evidence bundle: `reports/evidence/POS-0087/`
- JUnit: `reports/evidence/POS-0087/junit.xml`
- SARIF: `reports/evidence/POS-0087/palari.sarif`
- Attestation: `reports/evidence/POS-0087/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0087-reviewer-note.md`

## Risks / Follow-Ups

- Legacy `./bin/palari snapshot --json --full` is still slower than fast snapshot because it runs full role lint and includes closed tickets, but it now completes successfully in the stacked POS worktree.
- `dashboard_cards` are additive fast/web snapshot data; the legacy Bash company OS subsection remains unchanged for backward compatibility.
