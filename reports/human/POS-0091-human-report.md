# POS-0091 Human Report

## Why This Mattered

Palari had old and new human capacity fields living side by side. Future agents
need a safe way to detect and migrate old profiles without changing authority.

## What Changed

- Added `palari human migrate-capacity --check` to report old capacity fields.
- Added `palari human migrate-capacity --write` to migrate old capacity fields.
- New human profiles now use only the current operational capacity fields.
- After review, the migration was repaired so old `capacity_open_r3/r4/r5: 0`
  profiles keep the same HGL/workflow behavior after migration.
- Empty old capacity keys are now detected and removed during migration.
- Tests prove check mode is read-only, write mode refuses dirty repos,
  migration preserves legacy-zero behavior, empty old keys are removed, and
  migrated profiles still lint.

## What I Should Know

- This does not change who may approve work.
- This does not change HGL scoring.
- This does not migrate live profiles automatically.
- This does not change workflow planning, policy simulation, broker behavior,
  secrets, dependencies, deployment, or runtime state.
- Write mode requires a clean repo before changing files.

## What To Check

- Command: `./bin/palari human migrate-capacity --check`
- Command: `./tests/run-human-governance.sh`
- Path: `lib/palari/humans.bash`

## Recommended Next Move

POS-0091 is accept-ready after fresh-context re-review. If accepted later,
continue with the future integration contract phase in the plan.
