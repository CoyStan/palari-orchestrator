---
id: POS-0072
title: Add local sandbox broker for ticket-scoped repo-file work
status: accepted
risk: R4
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T13:10:52Z
claim_ref: refs/palari/claims/POS-0072
claim_heartbeat_at: 2026-06-15T23:27:30Z
claim_expires_at: 2026-06-15T23:32:30Z
allowed_paths:
  - adapters/broker/**
  - lib/palari/**
  - contracts/broker.md
  - tests/run-broker-mock.sh
  - tests/run-sandbox.sh
  - tickets/open/POS-0072-add-local-sandbox-broker-for-ticket-scoped-repo-file-work.md
  - tickets/closed/POS-0072-add-local-sandbox-broker-for-ticket-scoped-repo-file-work.md
  - reports/POS-0072-technical-report.md
  - reports/POS-0072-reviewer-note.md
  - reports/human/POS-0072-human-report.md
  - reports/evidence/POS-0072/**
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
  - ./tests/run-broker-mock.sh
  - ./tests/run-sandbox.sh
target_branch: main
branch: ticket/POS-0072
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-15T23:27:32Z
created: 2026-06-15
updated: 2026-06-15
---

# POS-0072 Add local sandbox broker for ticket-scoped repo-file work

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-broker-mock.sh
- ./tests/run-sandbox.sh

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
