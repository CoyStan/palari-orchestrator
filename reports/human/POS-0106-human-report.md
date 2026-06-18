# POS-0106 Human Report

## Why This Mattered

Generated files, caches, dependency folders, and build outputs should not
become normal ticket scope. The safer workflow is to classify them as hygiene
or fail clearly when they become tracked.

## What Changed

- Hygiene now reports tracked generated files and makes strict hygiene fail on
  them.
- Ticket lint now rejects generated artifact paths in `allowed_paths`.
- Local scope-check skips untracked generated dirt when it is not tracked by
  Git, so agents do not need to broaden scope for cache/build leftovers.
- The scope contract now says generated artifacts are hygiene issues, not
  legitimate implementation paths.

## What I Should Know

This does not delete generated files or caches. It also does not weaken CI
scope checks for committed branch diffs. Tracked generated artifacts remain a
problem to clean up or explicitly rescope with a better ticket.

## What To Check

- `lib/palari/hygiene.bash`
- `lib/palari/agents_review_scope.bash`
- `tests/run-hygiene.sh`
- `contracts/scope-and-paths.md`
- `reports/evidence/POS-0106/manifest.json`

## Recommended Next Move

Run fresh-context review for POS-0106. If the reviewer agrees the hygiene,
scope, and lint boundaries match the ticket contract, leave POS-0106 in review
for founder acceptance.
