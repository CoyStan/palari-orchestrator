# POS-0054 Technical Report

## Files Changed

- `lib/palari/demo.bash`
  - Added `palari demo --agent-refusal`.
  - The new path writes `DEM-0003`, a blocked mock-agent refusal fixture.
  - The fixture includes a handoff and preserved executor evidence under `reports/evidence/DEM-0003/executor/mock/`.
  - Hardened demo evidence reset with an explicit non-empty ticket id guard.
- `bin/palari`
  - Updated demo command usage and option help.
- `tests/run-demo.sh`
  - Added coverage for the `--agent-refusal` fixture, lint behavior, snapshot visibility, and `--force` replacement.
  - Added a local `fail` helper used by existing assertions.
- `README.md`
  - Documented the refusal fixture in the 5-minute demo, command table, and governance details.
- `CHANGELOG.md`
  - Added a POS-0054 unreleased entry.
- `tickets/open/POS-0054-add-mock-agent-refusal-demo.md`
  - Replaced placeholder text with the concrete goal, scope, non-goals, acceptance criteria, and evidence requirements.

## Verification

Passed:

- `bash -n bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh`
- `tests/run-demo.sh`
- `tests/run-agent-mock.sh`
- `shellcheck -x bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh`
- `git diff --check`

Observed non-blocking warning:

- Demo fixture `DEM-0003` has no `serves_goal` link during test execution. This is a local demo fixture warning only; the real POS-0054 ticket does not rely on DEM-0003 as tracked project work.

## CI Evidence

Final `./bin/palari ci POS-0054` evidence bundle:

- `reports/evidence/POS-0054/verification.log`
- `reports/evidence/POS-0054/junit.xml`
- `reports/evidence/POS-0054/palari.sarif`
- `reports/evidence/POS-0054/manifest.json`

## Risks / Follow-Ups

- `palari demo --agent-refusal` creates a deterministic fixture; it does not run opencode, Codex, Claude, or another real AI executor.
- The real mock executor lifecycle remains tested by `tests/run-agent-mock.sh`.
- This does not change scope-check, CI, acceptance, report-lint, or evidence validation behavior.
