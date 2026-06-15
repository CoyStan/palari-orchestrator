# POS-0086 Human Report

## Why This Mattered

Palari now has enough workflow and decision information that humans need a
single read-only place to see what needs judgment first.

## What Changed

- Added `./bin/palari decide inbox`.
- Added JSON output for the inbox.
- The inbox includes workflow expected decisions and open decision artifacts.
- It sorts higher-risk and higher-HGL decisions first.
- It shows required skills, coverage status, eligible humans, and policy
  candidate count.

## What I Should Know

- The inbox is read-only.
- It does not create or record decisions.
- It does not accept work, activate policies, or run agents.
- It does not change HGL scoring or authority rules.

## What To Check

- Command: `./bin/palari decide inbox`
- Command: `./bin/palari decide inbox --json`
- Command: `./tests/run-decisions.sh`
- Command: `./tests/run-workflow-planning.sh`

## Recommended Next Move

Fresh-context review POS-0086. If accepted later, continue to dashboard cards
that expose this governance state in the web/operator view.
