---
id: POS-0060
title: HGL coverage enforces human authority ceilings
status: accepted
risk: R3
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T11:08:02Z
claim_ref: refs/palari/claims/POS-0060
claim_heartbeat_at: 2026-06-15T20:23:23Z
claim_expires_at: 2026-06-16T20:23:23Z
allowed_paths:
  - adapters/planning/hgl.py
  - lib/palari/humans.bash
  - contracts/human-governance.md
  - contracts/human-governance-load.md
  - tests/run-human-governance-load.sh
  - tests/run-human-governance.sh
  - tests/fixtures/golden-flow
  - tickets/open/POS-0060-hgl-coverage-enforces-human-authority-ceilings.md
  - reports/POS-0060-technical-report.md
  - reports/POS-0060-reviewer-note.md
  - reports/human/POS-0060-human-report.md
  - reports/evidence/POS-0060/**
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
  - ./tests/run-company-os-demo.sh
  - ./tests/run-human-governance-load.sh
  - ./tests/run-human-governance.sh
  - ./tests/run-workflow-planning.sh
target_branch: codex/company-ai-os-next-phase
branch: ticket/POS-0060
worktree: 
accepted_by: founder
accepted_at: 2026-06-15T20:23:26Z
created: 2026-06-15
updated: 2026-06-15
acceptance_mode: human
---

# POS-0060 HGL coverage enforces human authority ceilings

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari human lint
- ./tests/run-company-os-demo.sh
- ./tests/run-human-governance-load.sh
- ./tests/run-human-governance.sh
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
