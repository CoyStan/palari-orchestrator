---
id: POS-0075
title: Centralize company OS artifact parsing
status: in-review
risk: R2
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T13:36:30Z
claim_ref: refs/palari/claims/POS-0075
claim_heartbeat_at: 2026-06-15T13:36:30Z
claim_expires_at: 2026-06-15T13:41:30Z
allowed_paths:
  - adapters/planning/**
  - tests/run-human-governance-load.sh
  - tests/run-workflow-planning.sh
  - tests/run-policy-simulation.sh
  - tests/run-policy-candidates.sh
  - tickets/open/POS-0075-centralize-company-os-artifact-parsing.md
  - tickets/closed/POS-0075-centralize-company-os-artifact-parsing.md
  - reports/POS-0075-technical-report.md
  - reports/POS-0075-reviewer-note.md
  - reports/human/POS-0075-human-report.md
  - reports/evidence/POS-0075/**
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
  - ./tests/run-human-governance-load.sh
  - ./tests/run-workflow-planning.sh
  - ./tests/run-policy-simulation.sh
  - ./tests/run-policy-candidates.sh
target_branch: main
branch: ticket/POS-0075
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0075 Centralize company OS artifact parsing

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-workflow-planning.sh
- ./tests/run-policy-simulation.sh
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
