# DEM-0004 Reviewer Note

## Review Result

Decision: accept-ready.

## Findings

- `palari demo --company-os` creates deterministic local fixtures for the
  Company OS shape: active workflow, two active humans, missing `privacy:L5`
  coverage, policy-candidate signal, mock broker evidence, and a recorded
  outcome.
- Existing `palari demo` and `palari demo --agent-refusal` behavior remains
  covered by `tests/run-demo.sh`.
- The Company OS demo test verifies workflow planning, policy candidate
  output, broker evidence JSON, `snapshot --json`, and `web --check`.
- The direct demo command does not run agents, access network services, accept
  tickets, push, merge, deploy, or enable broker side effects.
- Runtime fixture artifacts from the direct verification run were cleaned after
  CI so the committed branch contains code/tests/reports/evidence only.

## Verification Reviewed

Passed during implementation:

- `bash -n lib/palari/demo.bash`
- `./tests/run-demo.sh`
- `./tests/run-company-os-demo.sh`
- `./bin/palari demo --company-os --force >/tmp/palari-company-demo.out`
- `./bin/palari lint DEM-0004`
- `./bin/palari report-lint DEM-0004`
- `git diff --check`

Passed CI/evidence checks:

- `./bin/palari scope-check DEM-0004 --base ticket/SEC-0001`
- `./bin/palari ci DEM-0004 --base ticket/SEC-0001`
- `./bin/palari evidence score DEM-0004`

## Required Changes

None identified.

## Risks

- Local demo fixture files should not be confused with accepted production
  work.
- The policy candidate remains simulation-only and depends on the current
  conservative candidate heuristic.

## Recommendation

Accept DEM-0004.
