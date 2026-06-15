# POS-0067 Human Report

## Why This Mattered

Palari needs to make ticket acceptance intent visible before it can safely discuss future policy acceptance. This ticket adds that visibility without enabling policies to close work.

## What Changed

- New tickets now start with `acceptance_mode: human`.
- Normal human acceptance records `acceptance_mode: human`.
- R5 dual-human acceptance records `acceptance_mode: human_dual`.
- Policy acceptance attempts now fail with a plain simulation-only message.

## What I Should Know

- This does not enable real policy acceptance.
- Policy simulation remains read-only.
- Existing older tickets without `acceptance_mode` are treated as human acceptance mode for compatibility.

## What To Check

- Path: `lib/palari/tickets_workspace.bash`
- Path: `lib/palari/ci_accept.bash`
- Commands:
  - `./tests/run-policy-simulation.sh`
  - `./tests/run-risks.sh`
  - `bats tests/palari_acceptance.bats`

## Recommended Next Move

Fresh-context review POS-0067, then continue to POS-0068 if accept-ready.
