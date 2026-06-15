# POS-0077 Human Report

## Why This Mattered

Palari could show HGL for one workflow, but it did not yet answer the operator question: "What governance debt is making the system fragile right now?"

## What Changed

- Added `palari burden debt`.
- Added `palari burden debt --json`.
- Snapshot now includes a small Human Governance Debt summary.
- The report highlights missing skills, high-risk bottlenecks, weak evidence, capacity pressure, configured R5 human-quorum coverage gaps, and low-risk policy-candidate opportunities.

## What I Should Know

- This is read-only.
- It does not change HGL weights.
- It does not create policies, humans, workflows, tickets, decisions, outcomes, or broker actions.
- It is governance capacity planning, not employee productivity tracking.

## What To Check

- Command: `./bin/palari burden debt`
- Command: `./bin/palari burden debt --json`
- Command: `./tests/run-human-governance-load.sh`
- Command: `./tests/run-company-os-snapshot.sh`

## Recommended Next Move

Fresh-context review POS-0077, then continue to POS-0078 for the minimum viable human company planner if accept-ready.
