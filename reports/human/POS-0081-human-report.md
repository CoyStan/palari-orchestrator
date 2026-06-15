# POS-0081 Human Report

## Why This Mattered

Outcome records can now say whether the real human burden was higher or lower
than expected. Palari needs a way to summarize those lessons without quietly
changing governance rules.

## What Changed

- Added `./bin/palari burden calibrate`.
- Added JSON output with the same read-only calibration data.
- The report shows where HGL was overestimated or underestimated.
- The report shows predicted-vs-actual risk mismatches.
- The report shows successful policy-candidate classes and evidence patterns
  that reduced HGL.

## What I Should Know

- This does not change HGL weights.
- This does not activate policies.
- This does not accept work or grant authority.
- This does not change outcomes; it only reads recorded outcomes.
- Any actual calibration still needs a separate human-approved ticket.

## What To Check

- Command: `./bin/palari burden calibrate`
- Command: `./bin/palari burden calibrate --json`
- Command: `./tests/run-outcomes.sh`
- Command: `./tests/run-human-governance-load.sh`

## Recommended Next Move

Fresh-context review POS-0081. If accepted later, use the report as an input for
future human-approved HGL/policy tuning, not as an automatic governance change.
