---
id: POS-0067
title: Add explicit acceptance modes while keeping policy acceptance disabled
status: accepted
risk: R3
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T12:24:30Z
claim_ref: refs/palari/claims/POS-0067
claim_heartbeat_at: 2026-06-15T22:36:58Z
claim_expires_at: 2026-06-15T22:41:58Z
allowed_paths:
  - lib/palari/ci_accept.bash
  - lib/palari/tickets_workspace.bash
  - contracts/policy-acceptance.md
  - contracts/company-ai-os.md
  - tests/palari_acceptance.bats
  - tests/run-policy-simulation.sh
  - tickets/open/POS-0067-add-explicit-acceptance-modes-while-keeping-policy-acceptance-disabled.md
  - tickets/closed/POS-0067-add-explicit-acceptance-modes-while-keeping-policy-acceptance-disabled.md
  - reports/POS-0067-technical-report.md
  - reports/POS-0067-reviewer-note.md
  - reports/human/POS-0067-human-report.md
  - reports/evidence/POS-0067/**
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
  - ./tests/run-policy-simulation.sh
  - ./tests/run-risks.sh
target_branch: ticket/POS-0066
branch: ticket/POS-0067
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-15T22:37:08Z
created: 2026-06-15
updated: 2026-06-15
---

# POS-0067 Add explicit acceptance modes while keeping policy acceptance disabled

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./tests/run-policy-simulation.sh
- ./tests/run-risks.sh

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
