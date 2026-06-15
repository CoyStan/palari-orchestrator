---
id: POS-0076
title: Workflow plan includes human decision map
status: open
risk: R2
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - adapters/planning/workflow_plan.py
  - adapters/planning/hgl.py
  - contracts/workflows.md
  - contracts/human-governance-load.md
  - tests/run-workflow-planning.sh
  - tickets/open/POS-0076-workflow-plan-includes-human-decision-map.md
  - tickets/closed/POS-0076-workflow-plan-includes-human-decision-map.md
  - reports/POS-0076-technical-report.md
  - reports/POS-0076-reviewer-note.md
  - reports/human/POS-0076-human-report.md
  - reports/evidence/POS-0076/**
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
  - ./bin/palari workflow plan WF-9004
  - ./bin/palari workflow plan WF-9004 --json
  - ./tests/run-workflow-planning.sh
target_branch: main
branch: ticket/POS-0076
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0076 Workflow plan includes human decision map

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari workflow plan WF-9004
- ./bin/palari workflow plan WF-9004 --json
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
