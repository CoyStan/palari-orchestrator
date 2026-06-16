---
id: POS-0063
title: Human capacity affects HGL coverage and launch gates
status: accepted
risk: R3
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T11:34:18Z
claim_ref: refs/palari/claims/POS-0063
claim_heartbeat_at: 2026-06-15T20:08:49Z
claim_expires_at: 2026-06-16T20:08:49Z
allowed_paths:
  - lib/palari/humans.bash
  - adapters/planning/hgl.py
  - adapters/planning/workflow_plan.py
  - contracts/human-governance.md
  - templates/**
  - tests/run-human-governance.sh
  - tests/run-human-governance-load.sh
  - tests/run-workflow-planning.sh
  - tickets/open/POS-0063-human-capacity-affects-hgl-coverage-and-launch-gates.md
  - reports/POS-0063-technical-report.md
  - reports/POS-0063-reviewer-note.md
  - reports/human/POS-0063-human-report.md
  - reports/evidence/POS-0063/**
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
requires_human_confirmation: true
requires_review: true
verification:
  - ./bin/palari human lint
  - ./tests/run-human-governance.sh
  - ./tests/run-human-governance-load.sh
  - ./tests/run-workflow-planning.sh
target_branch: ticket/POS-0062
branch: ticket/POS-0063
worktree: 
accepted_by: founder
accepted_at: 2026-06-15T20:23:32Z
created: 2026-06-15
updated: 2026-06-15
acceptance_mode: human
---

# POS-0063 Human capacity affects HGL coverage and launch gates

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari human lint
- ./tests/run-human-governance.sh
- ./tests/run-human-governance-load.sh
- ./tests/run-workflow-planning.sh

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
