# POS-0071 Human Report

## Why This Mattered

Broker evidence needs a stable shape before Palari can move toward a stronger sandbox or real broker boundary. This ticket makes mock observations explicit and countable without giving the broker new authority.

## What Changed

- Each mock broker run now records a `broker-observation-v1` summary.
- The summary says the broker is `mock`, the boundary is `observed_only`, and side effects, credentials, and hosted/network access are disabled.
- Company OS snapshot tests now prove broker observations are counted.

## What I Should Know

- This is still not a security boundary.
- `signed_by: broker-mock` is a mock signer label, not human approval or cryptographic acceptance.
- The broker still does not perform real external actions.

## What To Check

- Path: `adapters/broker/mock_broker.py`
- Path: `contracts/broker.md`
- Command: `./tests/run-broker-mock.sh`
- Command: `./tests/run-company-os-snapshot.sh`

## Recommended Next Move

Fresh-context review POS-0071, then continue to POS-0072 for local sandbox broker mode if accept-ready.
