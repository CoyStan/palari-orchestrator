---
id: TKT-0001
title: short ticket title
stream: process
level: 1
parent_id:
root_id: TKT-0001
children: []
status: open
risk: R1
priority: P2
agents_allowed: 1
claimed_by:
claimed_at:
claim_token:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - path/or/glob/**
forbidden_paths:
  - .env
  - .env.*
  - "**/secrets/**"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
product_feel_review: not-applicable
verification:
  - describe the check or command
target_branch: main
branch: ticket/TKT-0001
worktree: ../repo-worktrees/TKT-0001
accepted_by:
accepted_at:
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# TKT-0001 Short Ticket Title

## Goal

State the result this ticket should produce.

## Scope

List what the agent may change or decide.

## Out Of Scope

List nearby work that must not be done in this ticket.

## Acceptance Criteria

- The expected result is clear.
- Required files or docs exist.
- The ticket's path and risk rules are respected.

## Ticket Completion Contract

Use this section for substantial tickets. For trivial R0 work, either complete
this section briefly or state why Acceptance Criteria and Verification are
enough.

### Goal

What this ticket must accomplish.

### Non-Goals

Nearby work this ticket must not absorb.

### Definition Of Done

- Concrete condition one.
- Concrete condition two.

### Evidence Required

- File, report, command, screenshot, browser review, or manual check the final
  reviewer must inspect.

### Expansion Rules

- A sub-ticket is allowed only when it satisfies or cleanly splits the original
  contract.
- Stop if objective, path scope, risk, or human-confirmation requirement
  changes.

### Final Review Gate

- Reviewer checks each Definition Of Done item and states whether it is
  satisfied, narrowed by the human/founder, blocked, or failed.

## Verification

- Name the command, read-through, or manual check required before review.

## Stop Conditions

- Stop if work needs a path outside `allowed_paths`.
- Stop if work touches `forbidden_paths`.
- Stop if risk is higher than declared.
- Stop if secrets, production, live external writes, deploys, Docker, database
  mutation, or destructive commands become necessary without explicit scope.
- Stop if acceptance criteria or authority are unclear.
