---
id: POS-0018
title: authority profiles and lifecycle audit
status: accepted
risk: R1
priority: P2
stream: governance
claimed_by: codex
claimed_at: 2026-06-07T19:40:30Z
claim_ref: refs/palari/claims/POS-0018
claim_heartbeat_at: 2026-06-07T19:40:54Z
claim_expires_at: 2026-06-07T20:40:54Z
allowed_paths:
  - .github/workflows/**
  - bin/palari
  - lib/palari/**
  - palari.config.yaml
  - schemas/**
  - README.md
  - AGENTS.md
  - contracts/**
  - roles/**
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
  - tests/run-authority-lifecycle.sh
  - tests/run-golden.sh
  - shellcheck -x bin/palari scripts/palari tests/run-authority-lifecycle.sh
target_branch: main
branch: ticket/POS-0018
worktree:
accepted_by: founder
accepted_at: 2026-06-07T19:43:22Z
created: 2026-06-07
updated: 2026-06-07
---

# POS-0018 authority profiles and lifecycle audit

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-authority-lifecycle.sh
- tests/run-golden.sh
- shellcheck -x bin/palari scripts/palari tests/run-authority-lifecycle.sh
