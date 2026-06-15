# POS-0063 Human Report

## Why This Mattered

Human capacity fields existed, but they were mostly decorative. Palari could
show coverage even when the only qualified human was already at capacity or had
no weekly governance budget left.

## What Changed

Profiles now lint current capacity against max/budget fields. HGL and workflow
planning now show available weekly HGL and risk-specific capacity failures.
Launch gates respond when a workflow exceeds available weekly governance
capacity.

## What I Should Know

This does not track employee productivity. It only models whether human
governance capacity exists for risky AI/company work.

## What To Check

- Over-budget human profiles fail `palari human lint`.
- R5 candidates at R5 capacity do not cover new R5 decisions.
- Workflow planning shows `capacity` with budget, current, available, and
  risk-capacity failures.
- Existing HGL and workflow planning tests remain green.

## Founder Acceptance

Pending.

## Recommended Next Move

Run fresh-context review for POS-0063. If accepted, continue to POS-0064 for
truthful company OS snapshot reporting.
