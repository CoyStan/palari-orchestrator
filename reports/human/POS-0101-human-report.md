# POS-0101 Human Report

## Why This Mattered

The minimax failure report showed that worktree handoff was too manual: agents could finish work in a ticket worktree, then copy evidence or reports around by hand and lose track of which branch was authoritative.

## What Changed

There is now a supported `palari worktree closeout ID` check. It must be run from the ticket worktree and reports whether the branch is ready to move to review or what exact command should happen next.

## What I Should Know

This ticket does not automate acceptance, merging, pushing, or deployment. It deliberately keeps closeout as a local readiness check so human authority remains unchanged.

## What To Check

Check that the output is understandable in the important failure cases: wrong checkout, dirty worktree, missing evidence, missing reports, scope failure, and ready-for-review.

## Recommended Next Move

If fresh-context review agrees, leave POS-0101 in review for founder acceptance later and continue to the next independent hardening ticket.
