# POS-0080 Human Report

## Why This Mattered

Outcomes are where Palari learns whether governed work actually helped, cost more human judgment than expected, or should inform future low-risk policy simulation.

## What Changed

- Outcome records now include optional metric impact fields.
- Outcome records now include predicted vs actual risk, HGL, human decision count, review outcome, rollback use, and policy-candidate flags.
- Outcome lint validates those fields when they are filled in.
- Policy candidates can show successful linked outcome counts and linked outcome impact metadata.

## What I Should Know

- This does not change HGL weights.
- This does not activate policies.
- This does not accept work or grant authority.
- Existing outcome records remain compatible.

## What To Check

- Command: `./bin/palari outcome lint`
- Command: `./tests/run-outcomes.sh`
- Command: `./tests/run-policy-candidates.sh`

## Recommended Next Move

Fresh-context review POS-0080, then continue to POS-0081 for read-only HGL calibration if accept-ready.
