---
id: POS-0014
title: Cleaner install adoption flow
status: accepted
risk: R2
priority: P2
stream: adoption
claimed_by: founder-closeout
claimed_at: 2026-06-07T09:17:15Z
claim_ref: refs/palari/claims/POS-0014
claim_heartbeat_at: 2026-06-07T09:17:15Z
claim_expires_at: 2026-06-07T13:17:15Z
allowed_paths:
  - bin/palari
  - README.md
  - contracts/**
  - skills/**
  - tests/**
  - .github/workflows/**
  - adapters/github/**
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-adoption.sh
  - tests/run-golden.sh
  - shellcheck -x bin/palari scripts/palari tests/run-adoption.sh
target_branch: main
branch: ticket/POS-0014
worktree:
accepted_by: founder
accepted_at: 2026-06-07T09:25:32Z
created: 2026-06-07
updated: 2026-06-07
---

# POS-0014 Cleaner install adoption flow

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-adoption.sh
- tests/run-golden.sh
- shellcheck -x bin/palari scripts/palari tests/run-adoption.sh

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
