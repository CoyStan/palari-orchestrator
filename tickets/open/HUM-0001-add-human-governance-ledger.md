---
id: HUM-0001
title: Add human governance ledger
status: claimed
risk: R3
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T22:40:19Z
claim_ref: refs/palari/claims/HUM-0001
claim_heartbeat_at: 2026-06-14T22:45:03Z
claim_expires_at: 2026-06-14T22:50:03Z
allowed_paths:
  - contracts/**
  - templates/**
  - humans/**
  - lib/palari/**
  - bin/palari
  - palari.config.yaml
  - schemas/**
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - README.md
  - tickets/open/HUM-0001*
  - tickets/closed/HUM-0001*
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
  - ./tests/run-human-governance.sh
  - ./tests/run-cli-structure.sh
target_branch: main
branch: ticket/HUM-0001
worktree:
accepted_by:
accepted_at:
created: 2026-06-14
updated: 2026-06-14
---

# HUM-0001 Add human governance ledger

## Goal

Add repo-native human governance profiles so later HGL scoring can reason about
skills, authority ceilings, capacity, and constraints.

## Scope

- Human governance directories and config.
- Human governance contract and template.
- Human governance CLI module and bin dispatch.
- Init/doctor support.
- Tests and documentation/state/changelog.

## Acceptance

- `palari human create` writes a proposed profile.
- `human list`, `show`, and `lint` work.
- `human adopt` moves proposed profiles to active with human bookkeeping.
- `human revoke` moves active profiles to revoked with human bookkeeping.
- Human lint validates active role/skill presence, skill levels, authority risk,
  R5 policy-approval flag, and non-negative capacity numbers.
- Profiles do not grant agent authority or introduce surveillance behavior.

## Verification

- ./tests/run-human-governance.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement HGL scoring or coverage matching.
- Do not implement workflow planning/autonomy ceilings.
- Do not add policy, broker, or outcome behavior.
- Do not turn profiles into agent identities or employee monitoring.

### Definition Of Done

- Human governance artifact directories exist.
- Human module is sourced by the CLI.
- Human lifecycle commands are documented and tested.
- Existing CLI structure checks remain green.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report because this is R3 work.
- Palari CI evidence.

### Expansion Rules

- Stop if the ledger would grant execution authority, bypass ticket gates,
  score humans automatically, or become productivity surveillance.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
