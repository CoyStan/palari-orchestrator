# POS-0066 Human Report

## Why This Mattered

R5 work changes Palari's authority layer. The repo should require real human
approval without forcing a solo founder to create fake second-human profiles.

## What Changed

- Human approval requirements are now configurable by risk tier with
  `governance.required_human_approvals`.
- The current repo sets R5 to one active authorized human for the solo-founder
  phase.
- `palari accept` still supports `--co-by`, including repeated `--co-by`, for
  team quorums of two or more.
- Secure doctor now reports the configured R5 human approval quorum and whether
  accept enforces it.

## What I Should Know

- This does not enable policy acceptance or autonomous acceptance.
- This does not make ForgeGate reviewer keys a substitute for human approval.
- Real R5 acceptance now requires the configured number of active human profiles
  with `authority_max_risk: R5` and `may_approve_policy_changes: true`.

## What To Check

- Path: `lib/palari/ci_accept.bash`
- Commands:
  - `./tests/run-risks.sh`
  - `./tests/run-secure-doctor.sh`
  - `./tests/run-human-governance-load.sh`
  - `bats tests/palari_acceptance.bats`

## Recommended Next Move

Fresh-context review POS-0066 carefully. If accept-ready, a founder/human should
explicitly decide whether to accept this R5 governance change; an agent must not
self-accept it.
