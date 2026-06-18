# POS-0102 Human Report

## Why This Mattered

Agents were getting trapped in stale evidence loops: CI evidence was valid at the implementation commit, but committing evidence and reports made `head_sha` look stale before acceptance.

## What Changed

There is now a supported `palari evidence refresh ID --base REF` command. It prepares CI evidence from the clean ticket worktree, refuses dirty or invalid states, and leaves review and human acceptance as separate actions.

## What I Should Know

The acceptance gate was not weakened for source changes. It only tolerates same-ticket bookkeeping after evidence, such as reports, evidence files, handoff notes, and ticket status metadata.

## What To Check

- Refresh fails from dirty worktrees.
- Invalid evidence is not silently overwritten.
- Source changes after evidence still block acceptance.
- Human/actor acceptance rules still pass their existing tests.

## Recommended Next Move

Fresh-context review should verify the new refresh path is bounded and that no acceptance authority, policy simulation, broker behavior, push, merge, or deploy behavior changed.
