---
id: POS-0068
title: Policy simulation is R2 max until broker and R5 controls mature
status: open
risk: R2
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
  - lib/palari/policies.bash
  - adapters/planning/policy_simulation.py
  - adapters/planning/policy_candidates.py
  - contracts/policy-acceptance.md
  - tests/run-policy-simulation.sh
  - tests/run-policy-candidates.sh
  - tickets/open/POS-0068-policy-simulation-is-r2-max-until-broker-and-r5-controls-mature.md
  - tickets/closed/POS-0068-policy-simulation-is-r2-max-until-broker-and-r5-controls-mature.md
  - reports/POS-0068-technical-report.md
  - reports/POS-0068-reviewer-note.md
  - reports/evidence/POS-0068/**
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
  - ./bin/palari policy lint
  - ./tests/run-policy-simulation.sh
  - ./tests/run-policy-candidates.sh
target_branch: ticket/POS-0067
branch: ticket/POS-0068
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0068 Policy simulation is R2 max until broker and R5 controls mature

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- ./bin/palari policy lint
- ./tests/run-policy-simulation.sh
- ./tests/run-policy-candidates.sh

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
