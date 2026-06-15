# POS-0085 Human Report

## Why This Mattered

The old company OS demo proved the machinery, but it looked like one red case.
The richer demo now shows the network shape: green, yellow, and red workflows
with different human governance needs.

## What Changed

- Added Growth, Support, and Engineering demo workflows.
- Added active founder/general manager, product/growth, technical/security, and
  customer/brand humans.
- Added a proposed privacy governor that does not count as active coverage.
- Kept one low-risk policy candidate, one mock broker observation, and one
  recorded outcome in the demo.

## What I Should Know

- The demo is deterministic and local.
- It does not create real broker side effects.
- It does not change HGL scoring or policy acceptance.
- It does not grant authority.

## What To Check

- Command: `./bin/palari demo --company-os --force`
- Command: `./tests/run-company-os-demo.sh`
- Command: `./tests/run-company-os-snapshot.sh`
- Command: `./bin/palari workflow plan WF-9101`
- Command: `./bin/palari workflow plan WF-9102`
- Command: `./bin/palari workflow plan WF-9103`

## Recommended Next Move

Fresh-context review POS-0085. If accepted later, continue to operator-facing
views such as the decision inbox and dashboard cards.
