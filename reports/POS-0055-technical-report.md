# POS-0055 Technical Report

## Files Changed

- `lib/palari/tickets_workspace.bash`
  - After `palari sandbox create` initializes the copied sandbox repo, the files produced by the sandbox's own `palari init` are committed into the sandbox baseline.
  - This keeps `sandbox list` and `sandbox inspect` clean immediately after creation.
- `CHANGELOG.md`
  - Added the POS-0055 unreleased note.
- `tickets/open/POS-0055-keep-sandbox-create-baseline-clean.md`
  - Added the concrete goal, scope, and acceptance criteria.

## Verification

Passed:

- `tests/run-sandbox.sh`
- `bash -n lib/palari/tickets_workspace.bash tests/run-sandbox.sh`
- `git diff --check`

## CI Evidence

Passed with `./bin/palari ci POS-0055 --base origin/codex/pos-0051-0054-batch`.
The POS-0055 patch is stacked on the accepted POS-0051..POS-0054 batch branch,
so using `main` as the base includes the earlier accepted batch paths and is
not a valid isolated POS-0055 scope check until that stack is integrated.

Evidence bundle:

- `reports/evidence/POS-0055/verification.log`
- `reports/evidence/POS-0055/junit.xml`
- `reports/evidence/POS-0055/palari.sarif`
- `reports/evidence/POS-0055/manifest.json`

Additional standalone checks passed against the live worktree:

- `./bin/palari scope-check POS-0055`
- `./bin/palari lint POS-0055`
- `tests/run-sandbox.sh`
- `git diff --check`

## Risks / Follow-Ups

- This changes only the local sandbox baseline. It does not change canonical repo state, sandbox destroy refusal checks, worktree creation, claim behavior, acceptance, or merge authority.
- The sandbox remains a local disposable repo copy, not a security boundary.
