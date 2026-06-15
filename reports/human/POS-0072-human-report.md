# POS-0072 Human Report

## Why This Mattered

Palari needs a safer way to observe repo-file work before any real broker authority exists. This ticket lets the broker run a command in a throwaway repo copy and report what would have changed.

## What Changed

- Added local sandbox broker mode.
- Allowed scoped sandbox changes are reported as `observed_allowed`.
- Forbidden or out-of-scope sandbox changes are reported as `denied_or_violation`.
- Evidence includes changed paths and a patch artifact.

## What I Should Know

- The real repo is not changed by sandbox broker runs.
- This is not a hardened security sandbox and does not enforce network isolation.
- No credentials, external writes, policy acceptance, push, merge, or deploy behavior was enabled.

## What To Check

- Command: `./bin/palari broker run TICKET --sandbox -- COMMAND`
- Command: `./bin/palari broker sandbox TICKET -- COMMAND`
- Command: `./tests/run-broker-mock.sh`
- Command: `./tests/run-sandbox.sh`

## Recommended Next Move

Fresh-context review POS-0072, then continue to POS-0073 for broker permission checks without execution if accept-ready.
