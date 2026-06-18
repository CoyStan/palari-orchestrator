# POS-0103 Human Report

## Why This Mattered

Retrospective tickets are useful when governance catches up to work that already
landed, but they are dangerous if they look identical to normal pre-governed
tickets. This ticket makes audit-backfill work visibly different.

## What Changed

- Retrospective tickets can be marked with `retrospective: true`.
- Retrospective tickets must list original landed commit SHAs.
- Retrospective tickets must explain why normal governance was bypassed.
- High-risk retrospective tickets cannot turn off reviewer or human/founder gates.
- Snapshots and packets expose retrospective state, original commits, and bypass reason.

## What I Should Know

This does not backfill any old tickets and does not accept anything. It only
adds the lifecycle rules and visibility needed for future audit-backfill tickets.

## What To Check

- `./tests/run-retrospective-governance.sh`
- `./bin/palari snapshot --json` on a retrospective ticket fixture
- `PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json` on the same fixture
- `./bin/palari lint TICKET` for a high-risk retrospective ticket with gates disabled

## Recommended Next Move

Run fresh-context review for POS-0103 and leave the ticket in review if the
reviewer finds it accept-ready.
