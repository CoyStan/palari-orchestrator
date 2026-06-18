# POS-0106 Technical Report

## Files Changed

- `contracts/scope-and-paths.md`
- `lib/palari/hygiene.bash`
- `lib/palari/agents_review_scope.bash`
- `tests/run-hygiene.sh`
- `tickets/open/POS-0106-scope-hygiene-generated-worktree-artifacts.md`

## Verification

- `bash -n lib/palari/hygiene.bash lib/palari/agents_review_scope.bash lib/palari/tickets_workspace.bash tests/run-hygiene.sh tests/run-worktree-closeout.sh tests/run-golden.sh`
- `./tests/run-hygiene.sh`
- `./tests/run-worktree-closeout.sh`
- `./tests/run-golden.sh`
- `./tests/run-cli-structure.sh`
- `./bin/palari scope-check POS-0106 --base ticket/POS-0105`
- `./bin/palari ci POS-0106 --base ticket/POS-0105`

## CI Evidence

- `reports/evidence/POS-0106/manifest.json`
- `reports/evidence/POS-0106/verification.log`
- `reports/evidence/POS-0106/junit.xml`
- `reports/evidence/POS-0106/palari.sarif`

## Risks / Follow-Ups

- Strict hygiene now fails tracked generated files separately from source dirt,
  so agents get a clear cleanup signal instead of treating committed artifacts
  as harmless generated drift.
- Ticket lint rejects generated artifact `allowed_paths`, which prevents
  papering over build/cache dirt by broadening ticket scope.
- Local untracked generated artifacts can be skipped by local scope-check when
  they are classified as generated and are not tracked by Git.
- CI/base scope checks still evaluate committed branch changes normally; this
  ticket does not make generated artifacts legitimate implementation scope.
