# HGL-0001 Human Report

## Why This Mattered

The Company AI OS roadmap depends on Palari being able to forecast how much
human judgment a workflow needs before AI work proceeds.

## What Changed

HGL-0001 adds:

- `palari burden score WF-ID [--json]`
- `palari human coverage WF-ID [--json]`
- a deterministic HGL scorer for workflow expected decisions
- visible missing skills, bottleneck roles, launch gates, and autonomy ceilings

## What I Should Know

This is read-only planning infrastructure. It does not accept work, move
tickets, activate policies, run agents, write externally, store credentials, or
grant agent authority.

## What To Check

- Workflows with covered R3/R4 decisions show constrained but usable gates.
- Workflows with missing R4/R5 skills fail conservative gates.
- JSON output is deterministic enough for later snapshot/planner work.

## Founder Acceptance

Founder pre-approval from Quetzali covers this marathon's review path.
HGL-0001 is accepted after green verification because it implements the planned
read-only burden scoring and coverage slice without expanding authority.

## Recommended Next Move

Accept HGL-0001 after verification, then continue to PLN-0001 for workflow
planning and autonomy explanations.
