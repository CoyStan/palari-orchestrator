---
id: POS-0013
title: Lead proposal planning layer
status: accepted
risk: R2
priority: P2
stream: orchestration
claimed_by: founder-closeout
claimed_at: 2026-06-07T09:17:15Z
claim_ref: refs/palari/claims/POS-0013
claim_heartbeat_at: 2026-06-07T09:17:15Z
claim_expires_at: 2026-06-07T13:17:15Z
allowed_paths:
  - bin/palari
  - palari.config.yaml
  - schemas/**
  - AGENTS.md
  - README.md
  - contracts/**
  - templates/**
  - skills/**
  - adapters/openclaude/**
  - .github/workflows/**
  - tests/**
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
  - tests/run-proposals.sh
  - tests/run-golden.sh
  - tests/run-agent-wrapper.sh
  - bash -n bin/palari tests/run-proposals.sh tests/run-golden.sh tests/run-agent-wrapper.sh
target_branch: main
branch: ticket/POS-0013
worktree:
accepted_by: founder
accepted_at: 2026-06-07T09:25:31Z
created: 2026-06-07
updated: 2026-06-07
---

# POS-0013 Lead proposal planning layer

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-proposals.sh
- tests/run-golden.sh
- tests/run-agent-wrapper.sh
- bash -n bin/palari tests/run-proposals.sh tests/run-golden.sh tests/run-agent-wrapper.sh

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
