# POS-0062 Human Report

## Why This Mattered

Before this ticket, a workflow could declare a high risk ceiling or high-risk
work unit and still look too autonomous if expected decisions were empty.

## What Changed

Workflow planning now explains where the highest risk came from:

- workflow risk ceiling
- work-unit risks
- expected-decision risks

R4/R5 work units now require expected human decision coverage in lint. R3 work
units without coverage produce a warning. R5 workflows no longer become high or
full autonomy just because expected decisions are missing.

## What I Should Know

This is planning/lint behavior only. It does not accept work, enable policy
acceptance, run broker actions, deploy, or touch secrets.

## What To Check

- `workflow plan --json` includes `risk_sources`.
- R5 ceiling with no decisions is `simulation_only`, not high/full autonomy.
- R4 work unit with no expected decision fails workflow lint.
- Existing Company OS demo and snapshot tests still pass.

## Founder Acceptance

Pending.

## Recommended Next Move

Run fresh-context review for POS-0062. If accepted, continue to POS-0063 for
operational human capacity semantics.
