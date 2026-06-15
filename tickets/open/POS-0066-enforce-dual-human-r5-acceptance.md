---
id: POS-0066
title: Enforce dual-human R5 acceptance
status: open
risk: R5
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
  - lib/palari/ci_accept.bash
  - lib/palari/humans.bash
  - contracts/company-ai-os.md
  - contracts/human-governance.md
  - contracts/signed-acceptance.md
  - README.md
  - tests/palari_acceptance.bats
  - tests/run-secure-doctor.sh
  - tests/run-risks.sh
  - tickets/open/POS-0066-enforce-dual-human-r5-acceptance.md
  - tickets/closed/POS-0066-enforce-dual-human-r5-acceptance.md
  - reports/POS-0066-technical-report.md
  - reports/POS-0066-reviewer-note.md
  - reports/human/POS-0066-human-report.md
  - reports/evidence/POS-0066/**
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
  - ./tests/run-risks.sh
  - ./tests/run-secure-doctor.sh
  - ./tests/run-gate-kernel.sh
target_branch: ticket/POS-0065
branch: ticket/POS-0066
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0066 Enforce dual-human R5 acceptance

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-risks.sh
- ./tests/run-secure-doctor.sh
- ./tests/run-gate-kernel.sh

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
