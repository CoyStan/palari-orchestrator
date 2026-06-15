# POS-0066 Human Report

## Why This Mattered

R5 work changes Palari's authority layer. A single actor should not be able to accept governance/kernel changes that affect how future AI work is authorized.

## What Changed

- R5 tickets now require two distinct active R5-authorized human profiles when dual-human R5 acceptance is configured.
- `palari accept` supports `--co-by` for that second human.
- Accepted R5 tickets record the second acceptor and `acceptance_mode: human_dual`.
- Secure doctor now reports R5 dual-human approval as enforced by `palari accept`.

## What I Should Know

- This does not enable policy acceptance or autonomous acceptance.
- This does not make ForgeGate reviewer keys a substitute for human approval.
- Real R5 acceptance now requires active human profiles with `authority_max_risk: R5` and `may_approve_policy_changes: true`.

## What To Check

- Path: `lib/palari/ci_accept.bash`
- Commands:
  - `./tests/run-risks.sh`
  - `./tests/run-secure-doctor.sh`
  - `bats tests/palari_acceptance.bats`

## Recommended Next Move

Fresh-context review POS-0066 carefully. If accept-ready, a founder/human should explicitly decide whether to accept this R5 governance change; an agent must not self-accept it.
