---
id: POS-0099
title: Governed bootstrap adoption lifecycle
status: claimed
risk: R4
priority: P1
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-17T22:48:56Z
claim_ref: refs/palari/claims/POS-0099
claim_heartbeat_at: 2026-06-17T22:48:56Z
claim_expires_at: 2026-06-17T22:53:56Z
allowed_paths:
  - lib/palari/init_adopt.bash
  - tests/run-adoption.sh
  - tests/run-cli-structure.sh
  - docs/**
  - tickets/open/POS-0099-*
  - tickets/closed/POS-0099-*
  - reports/POS-0099-technical-report.md
  - reports/POS-0099-reviewer-note.md
  - reports/human/POS-0099-human-report.md
  - reports/evidence/POS-0099/**
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
  - ./tests/run-adoption.sh
  - ./tests/run-cli-structure.sh
  - ./bin/palari ci POS-0099
target_branch: main
branch: ticket/POS-0099
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-17
updated: 2026-06-17
---

# POS-0099 Governed bootstrap adoption lifecycle

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-adoption.sh
- ./tests/run-cli-structure.sh
- ./bin/palari ci POS-0099

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
