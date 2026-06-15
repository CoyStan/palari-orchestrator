# POS-0060 Human Report

## Why This Mattered

Before this ticket, a person with the right skill level could satisfy high-risk
Human Governance Load coverage even when their authority ceiling was too low.
That made R5 planning look safer than it really was.

## What Changed

HGL coverage now checks skill, authority, and risk-specific capacity together.
For R5 decisions, the human must also have `may_approve_policy_changes: true`.

The output now explains why coverage failed, including:

- no active candidate
- underleveled candidate
- under-authorized candidate
- otherwise qualified candidate at risk capacity

## What I Should Know

This is governance math only. It does not accept tickets, run agents, change
policies, enable broker side effects, deploy, or touch secrets.

## What To Check

- A `privacy:L5` human with `authority_max_risk: R2` does not cover an R5 privacy decision.
- A `privacy:L5` human with R5 authority but without policy-change approval does not cover an R5 decision.
- A qualified R5 human at R5 capacity does not cover a new R5 decision.
- A qualified R5 human with capacity does cover the decision.

## Founder Acceptance

Pending.

## Recommended Next Move

Run fresh-context review for POS-0060. If accepted, continue to POS-0061 to fix
the known evidence-weighting defect.
