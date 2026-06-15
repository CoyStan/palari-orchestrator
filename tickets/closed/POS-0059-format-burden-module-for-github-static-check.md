---
id: POS-0059
title: Format burden module for GitHub static check
status: accepted
risk: R1
priority: P1
stream: tooling
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T05:15:07Z
claim_ref: refs/palari/claims/POS-0059
claim_heartbeat_at: 2026-06-15T05:15:07Z
claim_expires_at: 2026-06-15T05:20:07Z
allowed_paths:
  - lib/palari/burden.bash
  - reports/**
  - tickets/open/POS-0059*
  - tickets/closed/POS-0059*
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
requires_review: false
verification:
  - shfmt -d lib/palari/burden.bash
  - bash -n lib/palari/burden.bash
  - ./tests/run-human-governance-load.sh
  - ./bin/palari lint POS-0059
target_branch: main
branch: ticket/POS-0059
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T05:18:29Z
created: 2026-06-15
updated: 2026-06-15
---

# POS-0059 Format burden module for GitHub static check

## Goal

Keep the GitHub static-analysis workflow green for the Company AI OS roadmap
publication branch by applying the repository's shell formatting convention to
the HGL burden command module.

## Scope

This ticket may change only `lib/palari/burden.bash` formatting and the
standard POS-0059 ticket/report/evidence artifacts.

## Acceptance

- `shfmt -d lib/palari/burden.bash` reports no diff.
- The burden command module still parses as Bash.
- Human Governance Load tests still pass.
- No runtime behavior, roadmap capability, or governance boundary changes.

## Verification

- shfmt -d lib/palari/burden.bash
- bash -n lib/palari/burden.bash
- ./tests/run-human-governance-load.sh
- ./bin/palari lint POS-0059
