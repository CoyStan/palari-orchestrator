# POS-0082 Human Report

## Why This Mattered

Policy candidates should not be suggested just because the same low-risk decision
happened a few times. Palari should also notice when humans overrode the advice
or when outcomes failed.

## What Changed

- Policy candidates now show human approval and override rates.
- Policy candidates now show outcome success and rollback/failure rates.
- Policy candidates now show whether linked outcome evidence exists.
- Policy candidates now include a simple confidence label and score.
- Candidate reasons now explain the approval, override, outcome, and evidence
  signals behind the recommendation.

## What I Should Know

- Candidates are still limited to R0-R2 by default.
- Candidates are still simulation-only.
- Overrides and failed/rollback outcomes reduce confidence.
- No policy files are created or activated.
- This does not change acceptance, authority, HGL scoring, or broker behavior.

## What To Check

- Command: `./tests/run-policy-candidates.sh`
- Command: `./tests/run-outcomes.sh`
- Command: `./bin/palari policy candidates`
- Command: `./bin/palari policy candidates --json`

## Recommended Next Move

Fresh-context review POS-0082. If accepted later, continue to the operator-view
phase without turning policy suggestions into real acceptance.
