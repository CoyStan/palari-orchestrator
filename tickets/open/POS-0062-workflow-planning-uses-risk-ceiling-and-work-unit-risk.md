---
id: POS-0062
title: Workflow planning uses risk ceiling and work-unit risk
status: open
risk: R3
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - adapters/planning/hgl.py
  - adapters/planning/workflow_plan.py
  - lib/palari/workflows.bash
  - contracts/workflows.md
  - contracts/human-governance-load.md
  - tests/run-workflows.sh
  - tests/run-workflow-planning.sh
  - tests/run-company-os-snapshot.sh
  - tests/fixtures/golden-flow
  - tickets/open/POS-0062-workflow-planning-uses-risk-ceiling-and-work-unit-risk.md
  - reports/POS-0062-technical-report.md
  - reports/POS-0062-reviewer-note.md
  - reports/human/POS-0062-human-report.md
  - reports/evidence/POS-0062/**
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
  - ./bin/palari workflow lint
  - ./tests/run-workflows.sh
  - ./tests/run-workflow-planning.sh
  - ./tests/run-company-os-snapshot.sh
target_branch: ticket/POS-0061
branch: ticket/POS-0062
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0062 Workflow planning uses risk ceiling and work-unit risk

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari workflow lint
- ./tests/run-workflows.sh
- ./tests/run-workflow-planning.sh
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
