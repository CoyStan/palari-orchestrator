# POS-0102 Reviewer Note

## Review Result

Initial review: reopen.

Focused re-review after repair: accept-ready.

## Findings

Focused re-review findings: none. Both bounded reopen findings were addressed.

Initial reopen findings:

1. README acceptance-preparation flow is not executable as written. The documented flow runs `palari ci APP-0001 --base main` immediately before `palari evidence refresh APP-0001 --base main`, but `evidence refresh` requires a clean worktree and itself runs CI/evidence writing. Running `palari ci` first dirties `reports/evidence/...`, so the next command should refuse.

2. `cmd_evidence_refresh` does not fail before evidence rewrite for already-committed unrelated or out-of-scope source changes. It checks dirty local state before `cmd_ci`, but `cmd_ci` is the evidence-writing step and currently owns the scope check. Add a pre-write scope guard and regression coverage for a clean worktree with a committed out-of-scope path.

## Verification Reviewed

- POS-0102 CI evidence: passed, 5 tests, manifest present.
- `./tests/run-evidence-refresh.sh`: passed per log.
- `bats tests/palari_acceptance.bats`: 6 passed.
- `./bin/palari scope-check POS-0102 --base ticket/POS-0101`: ok, 15 paths.
- `./bin/palari report-lint POS-0102`: ok.
- `./bin/palari worktree closeout POS-0102`: ready-for-review.
- `./bin/palari packet POS-0102 reviewer`: failed in the nested stacked worktree with a missing declared worktree path.

Focused re-review verification:

- README flow now runs `palari scope-check`, then `palari evidence refresh`, without a prior `palari ci`.
- `cmd_evidence_refresh` now calls `evidence_refresh_require_scope_ok` before `cmd_ci`.
- Regression coverage adds `ERF-0005`, committing an out-of-scope file and asserting refresh fails before `reports/evidence/ERF-0005/manifest.json` is created.
- Current evidence shows passed status, 5 tests, 0 failures.
- Current check outputs show evidence score 100/100, report lint ok, scope-check ok, and worktree closeout ready-for-review.

## Required Changes

- None after focused re-review.

Completed repair items:

- Fixed the README acceptance-preparation command sequence so `evidence refresh` is the clean-worktree CI evidence path, not run after dirtying evidence with `palari ci`.
- Added and tested a pre-`cmd_ci` committed-scope guard for evidence refresh.
- Refreshed POS-0102 evidence after repair.

## Recommendation

Accept-ready. The packet-generation failure appears to be an adjacent nested-worktree path issue rather than a POS-0102 blocker because closeout reports ready from the registered POS-0102 worktree.
