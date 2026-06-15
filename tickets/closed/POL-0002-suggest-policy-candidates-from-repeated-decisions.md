---
id: POL-0002
title: Suggest policy candidates from repeated decisions
status: accepted
risk: R4
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-14T23:58:20Z
claim_ref: refs/palari/claims/POL-0002
claim_heartbeat_at: 2026-06-15T00:03:28Z
claim_expires_at: 2026-06-15T00:08:28Z
allowed_paths:
  - lib/palari/**
  - adapters/planning/**
  - decisions/**
  - memory/**
  - policies/**
  - bin/palari
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/POL-0002*
  - tickets/closed/POL-0002*
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
  - ./tests/run-policy-candidates.sh
  - ./tests/run-decisions.sh
target_branch: main
branch: ticket/POL-0002
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T00:03:42Z
created: 2026-06-14
updated: 2026-06-15
---

# POL-0002 Suggest policy candidates from repeated decisions

## Goal

Suggest conservative simulation policy candidates from repeated low-risk human
decisions, without creating or activating policy files.

## Scope

- `palari policy candidates`
- `palari policy candidates --json`
- Read-only candidate heuristics over decided decisions and linked ticket risk.
- Focused tests and reports.

## Acceptance

- Candidates are transparent and conservative.
- No policy files are created or activated automatically.
- Repeated R0-R2 decisions can produce suggestions.
- R3/R4/R5 decision classes are excluded from auto-accept suggestions.
- Existing decision lifecycle behavior is preserved.

## Verification

- ./tests/run-policy-candidates.sh
- ./tests/run-decisions.sh

## Ticket Completion Contract

### Non-Goals

- Outcome ledger support.
- Real policy acceptance.
- Policy activation lifecycle.
- Broker execution or side effects.
- Memory index rewrites.

### Definition Of Done

- Candidate command and JSON output exist.
- Heuristic groups repeated decided decisions by risk, kind, and
  recommendation/chosen pattern.
- Tests prove low-risk suggestions, high-risk exclusion, read-only behavior,
  and no automatic policy file creation.

### Evidence Required

- Technical report.
- Human/founder report.
- Fresh-context reviewer note.
- CI/evidence bundle.

### Expansion Rules

- Stop if the implementation needs to activate policies, accept tickets, mutate
  ticket lifecycle, merge, push, deploy, or perform broker side effects.

### Final Review Gate

- Reviewer confirms the candidate command is read-only, conservative, and
  excludes R3/R4/R5 auto-accept suggestions.
