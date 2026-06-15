---
id: POS-0061
title: Correct HGL evidence weighting
status: in-review
risk: R2
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T11:15:47Z
claim_ref: refs/palari/claims/POS-0061
claim_heartbeat_at: 2026-06-15T20:08:49Z
claim_expires_at: 2026-06-16T20:08:49Z
allowed_paths:
  - adapters/planning/hgl.py
  - contracts/human-governance-load.md
  - tests/run-human-governance-load.sh
  - tests/fixtures/golden-flow
  - tickets/open/POS-0061-correct-hgl-evidence-weighting.md
  - reports/POS-0061-technical-report.md
  - reports/POS-0061-reviewer-note.md
  - reports/evidence/POS-0061/**
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
  - ./tests/run-company-os-demo.sh
target_branch: ticket/POS-0060
branch: ticket/POS-0061
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0061 Correct HGL evidence weighting

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-company-os-demo.sh

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
