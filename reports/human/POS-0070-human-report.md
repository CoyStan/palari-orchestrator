# POS-0070 Human Report

## Why This Mattered

Palari needs a precise broker vocabulary before it can safely broker actions for agents. This ticket defines what an action request and broker result look like while keeping the broker mock-only.

## What Changed

- Broker requests now have a documented shape: actor, ticket, workflow, risk, tool, action, resource, side-effect class, and allow/deny reasons.
- Broker results now have a documented shape: observed/denied/failed status, decision reason, hashes, changed resources, and `side_effects_enabled: false`.
- Mock broker evidence now writes request/result artifacts for review.

## What I Should Know

- This does not enable real side effects.
- The mock broker is still observed-only, not a security boundary.
- `allowed` exists as future schema vocabulary, but this ticket does not emit real allowed side-effect decisions.

## What To Check

- Path: `contracts/broker.md`
- Path: `schemas/broker-action-request.schema.json`
- Path: `schemas/broker-result.schema.json`
- Command: `./tests/run-broker-mock.sh`
- Command: `./bin/palari broker status`

## Recommended Next Move

Fresh-context review POS-0070, then continue to POS-0071 for broker observation schema v1 if accept-ready.
