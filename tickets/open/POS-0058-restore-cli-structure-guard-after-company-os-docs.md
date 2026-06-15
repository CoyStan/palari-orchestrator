---
id: POS-0058
title: Restore CLI structure guard after Company OS docs
status: claimed
risk: R1
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T00:58:16Z
claim_ref: refs/palari/claims/POS-0058
claim_heartbeat_at: 2026-06-15T00:58:16Z
claim_expires_at: 2026-06-15T01:03:16Z
allowed_paths:
  - bin/palari
  - tests/run-cli-structure.sh
  - reports/**
  - tickets/open/POS-0058*
  - tickets/closed/POS-0058*
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
  - ./tests/run-cli-structure.sh
  - ./tests/run-state.sh
target_branch: main
branch: ticket/POS-0058
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0058 Restore CLI structure guard after Company OS docs

## Goal

Restore the CLI structure guard after Company OS command growth by keeping the
root entrypoint small and leaving detailed options to command-specific help.

## Scope

- Root CLI help text in `bin/palari`.
- The CLI structure test only if the guard itself needs clarification.
- POS-0058 reports/evidence/ticket bookkeeping.

## Acceptance

- `tests/run-cli-structure.sh` passes.
- `bin/palari` remains an entrypoint/dispatcher, not an implementation module.
- No runtime command behavior changes.

## Verification

- ./tests/run-cli-structure.sh
- ./tests/run-state.sh

## Ticket Completion Contract

### Non-Goals

- New command behavior.
- Company OS feature changes.
- Reworking command-specific help in modules.

### Definition Of Done

- Root help is compact enough for the line-count guard.
- Existing module sourcing and command dispatch remain intact.
- Verification passes.

### Evidence Required

- Technical report.
- Reviewer note.
- CI evidence bundle under `reports/evidence/POS-0058/`.

### Expansion Rules

- Stop if a larger CLI help redesign or module split is required.

### Final Review Gate

- Reviewer checks the line-count guard, no implementation drift into
  `bin/palari`, and green evidence.
