---
id: BRK-0001
title: Add mock broker evidence boundary
status: accepted
risk: R5
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T00:04:31Z
claim_ref: refs/palari/claims/BRK-0001
claim_heartbeat_at: 2026-06-15T00:09:43Z
claim_expires_at: 2026-06-15T00:14:43Z
allowed_paths:
  - contracts/**
  - adapters/broker/**
  - lib/palari/**
  - bin/palari
  - reports/evidence/**
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/BRK-0001*
  - tickets/closed/BRK-0001*
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
  - ./tests/run-broker-mock.sh
  - ./tests/run-evidence-quality.sh
target_branch: main
branch: ticket/BRK-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T00:09:54Z
created: 2026-06-15
updated: 2026-06-15
---

# BRK-0001 Add mock broker evidence boundary

## Goal

Lay the broker boundary with mock observed-command evidence, without enabling
real external side effects.

## Scope

- Broker contract.
- Mock broker adapter.
- `palari broker run TICKET-ID --mock -- COMMAND [ARGS...]`
- `palari broker evidence TICKET-ID [--json]`
- `palari broker status`
- Focused tests and reports.

## Acceptance

- Mock broker evidence exists and is listed.
- Evidence records command, cwd, exit code, stdout/stderr hashes, observed
  changed paths, and `side_effects_enabled: false`.
- Dangerous command patterns are refused before execution with evidence.
- No real credentials, hosted APIs, network side effects, or production writes
  are enabled.

## Verification

- ./tests/run-broker-mock.sh
- ./tests/run-evidence-quality.sh

## Ticket Completion Contract

### Non-Goals

- Real broker side effects.
- Credential storage or loading.
- Network or hosted API calls.
- Policy-based broker authorization.
- Snapshot broker counts beyond current static posture.

### Definition Of Done

- Broker contract and CLI exist.
- Mock run writes reviewable evidence.
- Broker evidence list works in text and JSON.
- Broker status clearly says real side effects are disabled.
- Tests cover successful mock run, dangerous refusal, no-`--mock` refusal,
  missing-ticket refusal, and evidence listing.

### Evidence Required

- Technical report.
- Human/founder report.
- Fresh-context reviewer note.
- CI/evidence bundle.

### Expansion Rules

- Stop if implementation needs real credentials, network calls, external writes,
  production state, policy-authorized side effects, or hosted APIs.

### Final Review Gate

- Reviewer confirms broker remains mock-only, side effects remain disabled, and
  evidence is reviewable.
