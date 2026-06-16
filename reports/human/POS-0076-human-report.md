# POS-0076 Human Report

## Why This Mattered

Workflow planning was showing aggregate HGL and decision counts, but not the exact human decisions still required. That made it harder for an operator to see which approvals, skills, or authority gaps were blocking a workflow.

## What Changed

- Workflow plans now show a human decision map.
- Each decision row shows the risk, action type, title, required skill, eligible humans, coverage status, and HGL score.
- R5 rows explicitly remain human-governed and say policy acceptance is not allowed.

## What I Should Know

- This is read-only planning output.
- It does not change HGL scoring or launch gates.
- It does not enable policy acceptance, broker actions, external side effects, or new autonomy.
- It does not create or move workflows, tickets, humans, policies, or outcomes.

## What To Check

- Command: `./bin/palari workflow plan WF-ID`
- Command: `./bin/palari workflow plan WF-ID --json`
- Command: `./tests/run-workflow-planning.sh`
- Command: `./tests/run-company-os-demo.sh`

## Recommended Next Move

Fresh-context review POS-0076, then continue to POS-0077 for a Human Governance Debt report if accept-ready.
