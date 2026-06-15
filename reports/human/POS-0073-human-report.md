# POS-0073 Human Report

## Why This Mattered

Before the broker runs anything, Palari should be able to answer whether a requested resource is inside the ticket boundary. This ticket adds that read-only check.

## What Changed

- Added `palari broker check`.
- The command can return JSON or readable text.
- It allows resources inside ticket scope and denies forbidden or outside-scope resources.
- Resource paths are normalized before checking, so traversal strings such as
  `allowed/../outside` fail closed instead of matching the raw allowed prefix.

## What I Should Know

- This command does not execute work.
- It does not write broker evidence.
- It does not grant real side-effect authority.

## What To Check

- Command: `./bin/palari broker check POS-0073 --tool filesystem --action write --resource adapters/broker/mock_broker.py --json`
- Command: `./tests/run-broker-mock.sh`

## Recommended Next Move

Fresh-context review POS-0073, then run the Phase 3 broker-hardening checks before continuing to POS-0075.
