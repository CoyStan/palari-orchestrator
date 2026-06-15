---
id: POS-0077
title: Add Human Governance Debt report
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
  - adapters/planning/**
  - lib/palari/**
  - contracts/human-governance-load.md
  - tests/run-human-governance-load.sh
  - tests/run-company-os-snapshot.sh
  - tickets/open/POS-0077-add-human-governance-debt-report.md
  - tickets/closed/POS-0077-add-human-governance-debt-report.md
  - reports/POS-0077-technical-report.md
  - reports/POS-0077-reviewer-note.md
  - reports/human/POS-0077-human-report.md
  - reports/evidence/POS-0077/**
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
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0077
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0077 Add Human Governance Debt report

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-company-os-snapshot.sh

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
