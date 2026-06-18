# POS-0101 Technical Report

## Files Changed

- `bin/palari`: forwards all `worktree` arguments and documents `worktree closeout ID`.
- `lib/palari/tickets_workspace.bash`: adds read-only `palari worktree closeout ID` readiness reporting.
- `tests/run-worktree-closeout.sh`: adds focused regression coverage for wrong checkout, dirty worktree, missing evidence, scope failure, and ready-for-review states.
- `README.md` and `contracts/worktree-first.md`: document the supported closeout path and remove the need for manual report/evidence copying.

## Verification

- `bash -n lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh`
- `shfmt -d bin/palari lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh`
- `shellcheck -x bin/palari lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh`
- `./tests/run-worktree-closeout.sh`
- `./tests/run-golden.sh`

## CI Evidence

- Pending `./bin/palari ci POS-0101`.
- Pending `./bin/palari evidence score POS-0101 --strict`.
- Pending `./bin/palari scope-check POS-0101`.
- Pending `./bin/palari report-lint POS-0101`.

## Risks / Follow-Ups

- The closeout command reports evidence presence and manifest integrity, but it does not solve the stale `head_sha` loop after evidence commits. That is intentionally left for the later atomic evidence refresh ticket.
- The command is read-only and does not move tickets, accept work, merge, push, deploy, or copy evidence between checkouts.
