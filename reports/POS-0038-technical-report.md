# POS-0038 Technical Report

## Summary

POS-0038 adds a Founder Inbox decision model to the dashboard snapshot and
local operator console. The inbox classifies active tickets into human gates,
blocked/evidence work, review needs, safe continuations, watch items, and
monitoring items so a founder/operator can quickly see what needs them versus
what an agent can keep doing.

The feature is read-only. It does not add browser-side accept, merge, push,
deploy, or lifecycle mutation.

## Changes

- Extended `operator` in `palari snapshot --json` with:
  - `operator.inbox`
  - `operator.inbox_counts`
- Added inbox item fields for ticket id, title, status, category, category
  label, action label, detail, command, actor, and severity.
- Added a Founder Inbox panel to the operator console.
- Prioritized inbox rendering so human gates and blockers appear before safe
  continuations.
- Updated the dashboard rubric to enforce the new DOM surface and snapshot
  contract.

## Files Changed

- `lib/palari/dashboard_snapshot.bash`
- `adapters/web/static/index.html`
- `adapters/web/static/app.js`
- `adapters/web/static/app-shell.css`
- `tests/run-dashboard-rubric.sh`
- `tickets/open/POS-0038-founder-inbox-decision-model.md`
- `reports/POS-0038-technical-report.md`

## Behavior

The snapshot now exposes an operator inbox like:

- `human-gate`: a human should accept/reopen or make a decision.
- `blocked`: scope, evidence, gate, or lifecycle state blocks progress.
- `evidence-needed`: CI evidence or reports are missing.
- `review-needed`: fresh reviewer work is needed.
- `can-continue`: a safe claim/isolate/continue action is available.
- `watch`: stale claim or other item to monitor.

The dashboard renders these items in a compact decision panel above the ticket
surfaces. Each command remains copy-only.

## Safety Boundaries

- No privileged browser action was added.
- Acceptance remains in `palari accept`.
- Merge, push, deploy, and production authority are unchanged.
- The inbox is derived from existing ticket next-action data and does not
  create new lifecycle state.

## Verification

Commands run during implementation:

- `bash -n lib/palari/dashboard_snapshot.bash lib/palari/adapters_snapshot.bash tests/run-dashboard-rubric.sh`
- `shellcheck -x lib/palari/dashboard_snapshot.bash`
- `node --check adapters/web/static/app.js`
- `python3 -m py_compile adapters/web/server.py`
- `./bin/palari snapshot --json`
- `tests/run-dashboard-rubric.sh`
- `git diff --check`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0038/verification.log`
- `reports/evidence/POS-0038/junit.xml`
- `reports/evidence/POS-0038/manifest.json`
- `reports/evidence/POS-0038/palari.sarif`

## Risks / Follow-Ups

- Snapshot generation still inherits existing per-ticket report/evidence checks;
  POS-0038 avoids an extra count pass, but broader snapshot performance can be
  improved in a future ticket.
- The inbox is a decision surface, not an autonomous runner.
- A future ticket can use this inbox as the base for `palari run --until
  blocked` dry-run planning and dashboard Founder Inbox copy refinements.
