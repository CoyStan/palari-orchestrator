---
id: POS-0070
title: Define broker resource and action permission model
status: open
risk: R4
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
  - contracts/broker.md
  - contracts/company-ai-os.md
  - schemas/**
  - adapters/broker/mock_broker.py
  - tests/run-broker-mock.sh
  - tickets/open/POS-0070-define-broker-resource-and-action-permission-model.md
  - tickets/closed/POS-0070-define-broker-resource-and-action-permission-model.md
  - reports/POS-0070-technical-report.md
  - reports/POS-0070-reviewer-note.md
  - reports/human/POS-0070-human-report.md
  - reports/evidence/POS-0070/**
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
  - ./bin/palari broker status
target_branch: main
branch: ticket/POS-0070
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0070 Define broker resource and action permission model

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-broker-mock.sh
- ./bin/palari broker status

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
