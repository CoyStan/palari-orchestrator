# POS-0102 Technical Report

## Files Changed

- `bin/palari`
- `lib/palari/ci_accept.bash`
- `lib/palari/evidence_quality.bash`
- `lib/palari/tickets_workspace.bash`
- `contracts/worktree-first.md`
- `README.md`
- `tests/run-evidence-refresh.sh`
- `tests/palari_acceptance.bats`
- `reports/evidence/POS-0102/**`

## Verification

- `bash -n lib/palari/ci_accept.bash lib/palari/evidence_quality.bash lib/palari/tickets_workspace.bash tests/run-evidence-refresh.sh`
- `shfmt -d bin/palari lib/palari/ci_accept.bash lib/palari/evidence_quality.bash lib/palari/tickets_workspace.bash tests/run-evidence-refresh.sh`
- `shellcheck -x bin/palari lib/palari/ci_accept.bash lib/palari/evidence_quality.bash lib/palari/tickets_workspace.bash tests/run-evidence-refresh.sh`
- `./tests/run-evidence-refresh.sh`
- `bats tests/palari_acceptance.bats`
- `./bin/palari evidence refresh POS-0102 --base ticket/POS-0101`

## CI Evidence

- `reports/evidence/POS-0102/manifest.json`
- Manifest `head_sha`: `65fbabe072dba7e255a92f0f9bd918e3fbdd6d27`
- Status: passed
- Tests: 5
- Failures: 0
- Skipped: 0

## Implementation Notes

- Added `palari evidence refresh ID [--base REF]` as the supported acceptance-preparation path.
- The refresh command verifies ticket branch/worktree context, requires a clean worktree, refuses invalid existing evidence that is not merely stale by commit, runs `palari ci`, validates the refreshed manifest, and prints review/acceptance next commands.
- The repair pass added a pre-CI scope guard so clean but already-committed out-of-scope changes fail before evidence is rewritten.
- The README flow now uses `palari evidence refresh` as the clean-worktree CI evidence path instead of running `palari ci` first.
- Acceptance/evidence freshness now permits only same-ticket evidence, report, handoff, and ticket bookkeeping commits after the manifest `head_sha`.
- Source or unrelated commits after evidence still fail acceptance/evidence freshness and require a refresh.
- `worktree closeout` now uses the same current-manifest freshness check instead of treating integrity-only evidence as ready.
- The Bats acceptance fixture now clears copied repo ticket/report/evidence state so active stacked POS tickets do not collide with fixture IDs.

## Risks / Follow-Ups

- This does not automate acceptance, merge, push, deploy, or PR creation.
- Invalid failed/corrupt evidence must be inspected or removed before refresh; the command intentionally refuses to overwrite it silently.
- Same-ticket bookkeeping drift is intentionally narrow. If future required artifacts use new directories, those paths should be added explicitly with tests.
