# POS-0099 Human Report

## Why This Mattered

The minimax incident showed that large governance imports can happen before
Palari has a durable record of what is being imported, what is excluded, and who
approved the write. Scope-check caught the damage later, but the safer product
shape is to make adoption produce a reviewable artifact before files are
written.

## What Changed

- `palari adopt --dry-run` remains the safe preview path.
- `palari adopt plan TARGET --out FILE` now writes a bootstrap/adoption plan.
- Non-dry-run `palari adopt TARGET` now requires `--plan FILE`.
- A proposed plan cannot write files; a human must mark it approved first.
- The plan records source, target, path manifest, exclusions, and downstream
  customization boundaries.
- Approved adoption now fails if the source copied files/symlinks or the target
  worktree changed after the plan was reviewed.
- README and the adoption contract now describe the governed flow.

## What I Should Know

- This does not accept, merge, push, or deploy anything.
- This does not weaken scope-check. It makes the intended adoption path more
  explicit before target files are changed.
- This does not solve every downstream adoption issue. In particular, separating
  upstream self-tests/history from downstream active governance remains a later
  ticket in the minimax hardening stack.

## What To Check

- `lib/palari/init_adopt.bash`
- `tests/run-adoption.sh`
- `README.md`
- `contracts/adoption.md`
- Run `./tests/run-adoption.sh`

## Recommended Next Move

Run Palari CI/evidence checks and fresh-context review. If the reviewer agrees,
leave POS-0099 in review for later founder acceptance.
