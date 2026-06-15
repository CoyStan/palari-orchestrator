---
id: POS-0071
title: Broker evidence uses signed observation schema v1
status: accepted
risk: R3
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T13:00:50Z
claim_ref: refs/palari/claims/POS-0071
claim_heartbeat_at: 2026-06-15T23:26:47Z
claim_expires_at: 2026-06-15T23:31:47Z
allowed_paths:
  - adapters/broker/**
  - contracts/broker.md
  - reports/evidence/**
  - tests/run-broker-mock.sh
  - tests/run-company-os-snapshot.sh
  - tickets/open/POS-0071-broker-evidence-uses-signed-observation-schema-v1.md
  - tickets/closed/POS-0071-broker-evidence-uses-signed-observation-schema-v1.md
  - reports/POS-0071-technical-report.md
  - reports/POS-0071-reviewer-note.md
  - reports/human/POS-0071-human-report.md
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
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0071
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-15T23:26:49Z
created: 2026-06-15
updated: 2026-06-15
---

# POS-0071 Broker evidence uses signed observation schema v1

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-broker-mock.sh
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
