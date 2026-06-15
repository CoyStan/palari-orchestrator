# WFU-0001 Human Report

## Why This Mattered

Workflows are the first Company OS artifact above tickets. They let Palari
model a business process before splitting it into implementation tickets and
human decisions.

## What Changed

WFU-0001 adds workflow directories, a workflow contract/template, and
`palari workflow create|list|show|lint|adopt|close`.

## What I Should Know

This does not run agents or grant authority. Adoption and closure are explicit
human bookkeeping actions, and workflow planning/HGL scoring still belongs to
later tickets.

## What To Check

- Workflow creation writes proposed artifacts.
- Workflow lint catches invalid goals, risks, work units, and R3/R4/R5
  decisions without skills.
- No acceptance, policy, broker, deployment, or credential behavior changed.

## Recommended Next Move

Accept WFU-0001 after verification, then continue to the human governance
ledger.
