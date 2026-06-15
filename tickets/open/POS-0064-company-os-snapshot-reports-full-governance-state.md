---
id: POS-0064
title: Company OS snapshot reports full governance state
status: in-review
risk: R2
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T11:46:17Z
claim_ref: refs/palari/claims/POS-0064
claim_heartbeat_at: 2026-06-15T11:46:17Z
claim_expires_at: 2026-06-15T11:51:17Z
allowed_paths:
  - adapters/planning/company_os_snapshot.py
  - adapters/snapshot/**
  - adapters/web/**
  - lib/palari/dashboard_snapshot.bash
  - tests/run-company-os-snapshot.sh
  - tests/run-dashboard-rubric.sh
  - tests/run-company-os-demo.sh
  - tickets/open/POS-0064-company-os-snapshot-reports-full-governance-state.md
  - reports/POS-0064-technical-report.md
  - reports/POS-0064-reviewer-note.md
  - reports/evidence/POS-0064/**
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
  - ./bin/palari snapshot --json
  - ./bin/palari web --check
  - ./tests/run-company-os-snapshot.sh
  - ./tests/run-dashboard-rubric.sh
target_branch: ticket/POS-0063
branch: ticket/POS-0064
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0064 Company OS snapshot reports full governance state

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari snapshot --json
- ./bin/palari web --check
- ./tests/run-company-os-snapshot.sh
- ./tests/run-dashboard-rubric.sh

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
