---
id: POS-0065
title: Secure doctor distinguishes configured and enforced controls
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
  - lib/palari/**
  - contracts/company-ai-os.md
  - contracts/signed-acceptance.md
  - tests/run-secure-doctor.sh
  - tickets/open/POS-0065-secure-doctor-distinguishes-configured-and-enforced-controls.md
  - reports/POS-0065-technical-report.md
  - reports/POS-0065-reviewer-note.md
  - reports/human/POS-0065-human-report.md
  - reports/evidence/POS-0065/**
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
  - ./bin/palari doctor secure
  - ./tests/run-secure-doctor.sh
target_branch: ticket/POS-0064
branch: ticket/POS-0065
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0065 Secure doctor distinguishes configured and enforced controls

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari doctor secure
- ./tests/run-secure-doctor.sh

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
