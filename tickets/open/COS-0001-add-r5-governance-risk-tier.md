---
id: COS-0001
title: Add R5 governance risk tier
status: claimed
risk: R4
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T22:17:29Z
claim_ref: refs/palari/claims/COS-0001
claim_heartbeat_at: 2026-06-14T22:21:20Z
claim_expires_at: 2026-06-14T22:26:20Z
allowed_paths:
  - lib/palari/**
  - palari.config.yaml
  - schemas/**
  - contracts/**
  - roles/**
  - tests/**
  - README.md
  - STATE.md
  - CHANGELOG.md
  - tickets/open/COS-0001*
  - tickets/closed/COS-0001*
  - reports/**
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
  - ./tests/run-cli-structure.sh
  - ./tests/run-roles.sh
  - ./tests/run-model-routing.sh
target_branch: main
branch: ticket/COS-0001
worktree:
accepted_by:
accepted_at:
created: 2026-06-14
updated: 2026-06-14
---

# COS-0001 Add R5 governance risk tier

## Goal

Add R5 as the first-class governance/kernel risk tier used by tickets, roles,
evidence/readiness checks, and model routing.

## Scope

- Shared risk validation and role risk ranking.
- Ticket creation gates for R5.
- Report/evidence/dashboard readiness rules for R5.
- Model routing/config/schema entries for R5.
- Root role maximum risk.
- README/contract/state/changelog documentation.
- Focused risk tests.

## Acceptance

- `palari ticket create ... --risk R5` succeeds.
- R5 tickets automatically require review and human confirmation.
- Invalid risk values still fail closed.
- Role lint accepts `ROLE-ROOT` with `max_risk: R5`.
- Evidence/report readiness treats R5 as human-gated.
- Model routing maps R5 to `frontier` by default.

## Verification

- ./tests/run-risks.sh
- ./tests/run-cli-structure.sh
- ./tests/run-roles.sh
- ./tests/run-model-routing.sh

## Ticket Completion Contract

### Non-Goals

- Do not add workflow artifacts or HGL scoring.
- Do not add policy simulation, broker, or outcome commands.
- Do not enable autonomous acceptance.
- Do not change ForgeGate behavior.

### Definition Of Done

- R5 is valid in the shared risk list.
- R5 ticket creation is gated like R3/R4 plus governance wording.
- R5 role ranking is higher than R4.
- Tests cover R5 creation, invalid R6, role lint, evidence/report gates, and
  model routing.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report because this is R4 governance work.
- Palari CI evidence.

### Expansion Rules

- Stop if work requires real autonomous acceptance, live broker side effects,
  production mutation, or credential access.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
