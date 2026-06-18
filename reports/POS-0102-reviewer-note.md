# POS-0102 Reviewer Note

## Review Result

Reopen.

## Findings

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

## Required Changes

- Fix the README acceptance-preparation command sequence so `evidence refresh` is the clean-worktree CI evidence path, not run after dirtying evidence with `palari ci`.
- Add and test a pre-`cmd_ci` committed-scope guard for evidence refresh.
- Refresh POS-0102 evidence after repair.

## Recommendation

Reopen until the bounded documentation and pre-write scope guard findings are fixed and re-reviewed.
