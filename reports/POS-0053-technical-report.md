# POS-0053 Technical Report

## Files Changed

- `bin/palari`
  - Changed `snapshot` dispatch so `palari snapshot --json --full` is accepted.
  - Updated usage text to document the optional full snapshot mode.
- `lib/palari/adapters_snapshot.bash`
  - Added fast/full mode parsing for `snapshot --json`.
  - Made default snapshots omit accepted-ticket history and use the active-ticket fast serializer.
  - Added `web --check --full` for deliberate audit snapshots.
- `lib/palari/dashboard_snapshot.bash`
  - Added fast ticket, role, report, and evidence summary serializers for the live dashboard contract.
  - Kept full mode wired to full report diagnostics and full role lint.
- `adapters/web/README.md`
  - Documented the fast operator view versus full diagnostic snapshot.
- `tests/run-dashboard-rubric.sh`
  - Added assertions for `snapshot_mode: fast`, shallow role diagnostics, no accepted tickets in the default dashboard payload, and accepted-ticket/full-role-lint behavior in `--full`.
- `tickets/open/POS-0053-make-default-snapshot-fast.md`
  - Replaced placeholder ticket text with the concrete contract, non-goals, and review requirements.
- `CHANGELOG.md`
  - Added a POS-0053 unreleased entry.

## Verification

Measured in `/home/quetza/palari-orchestrator-worktrees/POS-0051-0054-batch` on this batch branch:

- Before this ticket, the baseline from `origin/main` was approximately:
  - `./bin/palari snapshot --json`: 61.07s
  - `./bin/palari web --check`: 61.93s
- After this ticket:
  - `./bin/palari snapshot --json`: 4.80s to 5.73s across repeated runs
  - `./bin/palari web --check`: 4.73s
  - `./bin/palari snapshot --json --full`: 63.45s

Passed:

- `bash -n lib/palari/dashboard_snapshot.bash lib/palari/adapters_snapshot.bash bin/palari`
- `./bin/palari snapshot --json`
- `./bin/palari web --check`
- `./bin/palari snapshot --json --full`
- `tests/run-dashboard-rubric.sh`
- `tests/run-cli-structure.sh`
- `python3 -m py_compile adapters/web/server.py`
- `git diff --check`

## CI Evidence

Final `./bin/palari ci POS-0053` evidence bundle:

- `reports/evidence/POS-0053/verification.log`
- `reports/evidence/POS-0053/junit.xml`
- `reports/evidence/POS-0053/palari.sarif`
- `reports/evidence/POS-0053/manifest.json`

## Risks / Follow-Ups

- Fast mode intentionally uses presence-based report/evidence summaries and shallow role diagnostics. It is meant for the live console, not final gate enforcement.
- Full mode remains the correct path for audit-grade review of accepted-ticket history, complete report diagnostics, and full role lint.
- This does not change `palari lint`, `palari ci`, `palari accept`, evidence validation, role lint, report lint, or scope enforcement.
