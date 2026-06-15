---
id: OUT-0001
title: Add outcome ledger
status: accepted
risk: R3
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T00:11:05Z
claim_ref: refs/palari/claims/OUT-0001
claim_heartbeat_at: 2026-06-15T00:17:47Z
claim_expires_at: 2026-06-15T00:22:47Z
allowed_paths:
  - contracts/**
  - templates/**
  - outcomes/**
  - lib/palari/**
  - bin/palari
  - adapters/planning/**
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/OUT-0001*
  - tickets/closed/OUT-0001*
  - reports/**
  - palari.config.yaml
  - schemas/palari.config.schema.json
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
  - ./tests/run-outcomes.sh
  - ./tests/run-policy-candidates.sh
target_branch: main
branch: ticket/OUT-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T00:17:57Z
created: 2026-06-15
updated: 2026-06-15
---

# OUT-0001 Add outcome ledger

## Goal

Add a repo-native outcome ledger so Palari can record what happened after
governed work and later use those records for policy/HGL learning.

## Scope

- Outcome directories and config keys.
- Outcome contract and template.
- `palari outcome create|list|show|lint|record`.
- Policy candidate output may cite linked recorded outcomes.
- Focused tests and reports.

## Acceptance

- Outcomes are visible and lintable.
- Outcomes can be moved from open to recorded by a human.
- Outcome lint checks linked workflow, goal, ticket, decision, and evidence
  references when present.
- Outcomes do not accept work or claim business impact without evidence.
- Policy candidates can cite linked recorded outcomes.

## Verification

- ./tests/run-outcomes.sh
- ./tests/run-policy-candidates.sh

## Ticket Completion Contract

### Non-Goals

- Outcome analytics/scoring.
- Real policy acceptance.
- Broker side effects.
- Dashboard outcome cards.
- Snapshot outcome counts beyond policy candidate citation.

### Definition Of Done

- Outcome artifact lifecycle exists.
- Tests cover create/list/show/lint/record and bad-reference lint failure.
- Policy candidates report linked recorded outcomes when present.

### Evidence Required

- Technical report.
- Human/founder report.
- Fresh-context reviewer note.
- CI/evidence bundle.

### Expansion Rules

- Stop if implementation needs to accept tickets, activate policies, mutate
  broker side effects, or infer business impact without linked evidence.

### Final Review Gate

- Reviewer confirms outcomes are ledger records only and policy candidates use
  them as context rather than authority.
