---
id: POS-0080
title: Outcome records include metric and governance impact
status: open
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - lib/palari/outcomes.bash
  - contracts/outcomes.md
  - templates/**
  - adapters/planning/**
  - tests/run-outcomes.sh
  - tests/run-policy-candidates.sh
  - tickets/open/POS-0080-outcome-records-include-metric-and-governance-impact.md
  - tickets/closed/POS-0080-outcome-records-include-metric-and-governance-impact.md
  - reports/POS-0080-technical-report.md
  - reports/POS-0080-reviewer-note.md
  - reports/human/POS-0080-human-report.md
  - reports/evidence/POS-0080/**
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
  - "**/*.keystore"
  - "**/*.p12"
  - "**/id_rsa*"
  - "**/id_ed25519*"
  - "**/credentials*"
  - "**/.aws/**"
  - "**/.ssh/**"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - ./bin/palari outcome lint
  - ./tests/run-outcomes.sh
  - ./tests/run-policy-candidates.sh
target_branch: main
branch: ticket/POS-0080
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0080 Outcome records include metric and governance impact

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari outcome lint
- ./tests/run-outcomes.sh
- ./tests/run-policy-candidates.sh

## Ticket Completion Contract

### Non-Goals

- Nearby work this ticket must not absorb.

### Definition Of Done

- Concrete done condition.

### Evidence Required

- Report, command, review, screenshot, or manual check to inspect.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
