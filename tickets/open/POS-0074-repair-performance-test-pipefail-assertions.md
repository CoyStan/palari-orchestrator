---
id: POS-0074
title: Repair performance test pipefail assertions
status: in-review
risk: R1
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T13:25:29Z
claim_ref: refs/palari/claims/POS-0074
claim_heartbeat_at: 2026-06-15T13:25:29Z
claim_expires_at: 2026-06-15T13:30:29Z
allowed_paths:
  - tests/run-performance.sh
  - tickets/open/POS-0074-repair-performance-test-pipefail-assertions.md
  - tickets/closed/POS-0074-repair-performance-test-pipefail-assertions.md
  - reports/POS-0074-technical-report.md
  - reports/POS-0074-reviewer-note.md
  - reports/human/POS-0074-human-report.md
  - reports/evidence/POS-0074/**
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
  - ./tests/run-performance.sh
target_branch: main
branch: ticket/POS-0074
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0074 Repair performance test pipefail assertions

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-performance.sh
