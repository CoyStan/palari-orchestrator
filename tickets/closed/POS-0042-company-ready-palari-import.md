---
id: POS-0042
title: Company-ready Palari import
status: accepted
risk: R2
priority: P0
stream: governance
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T08:43:02Z
claim_ref: refs/palari/claims/POS-0042
claim_heartbeat_at: 2026-06-11T08:43:02Z
claim_expires_at: 2026-06-11T08:48:02Z
allowed_paths:
  - .gitattributes
  - .github/**
  - AGENTS.md
  - CHANGELOG.md
  - README.md
  - agent-skills/**
  - bin/palari
  - contracts/**
  - decisions/**
  - docs/autonomy/**
  - goals/**
  - lib/palari/**
  - palari.config.yaml
  - reports/**
  - research/pilots/**
  - roles/**
  - schemas/**
  - templates/**
  - tests/**
  - tickets/**
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
required_reports:
  - technical
verification:
  - git diff --check
  - ./bin/palari lint
  - tests/run-github-ci.sh
  - tests/run-goals.sh
  - tests/run-decisions.sh
  - tests/run-queue-dry-run.sh
target_branch: main
branch: ticket/POS-0042
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T08:45:18Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0042 Company-ready Palari import

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- git diff --check
- ./bin/palari lint
- tests/run-github-ci.sh
- tests/run-goals.sh
- tests/run-decisions.sh
- tests/run-queue-dry-run.sh

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
