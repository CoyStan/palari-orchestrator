---
id: POS-0053
title: Make default snapshot fast
status: open
risk: R2
priority: P0
stream: dashboard
serves_goal: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - lib/palari/dashboard_snapshot.bash
  - adapters/web/server.py
  - adapters/web/README.md
  - tests/run-dashboard-rubric.sh
  - tests/run-cli-structure.sh
  - .github/workflows/**
  - CHANGELOG.md
  - tickets/open/POS-0053*
  - tickets/closed/POS-0053*
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
requires_human_confirmation: false
requires_review: true
required_reports:
  - technical
verification:
  - tests/run-dashboard-rubric.sh
  - tests/run-cli-structure.sh
  - python3 -m py_compile adapters/web/server.py
target_branch: main
branch: ticket/POS-0053
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0053 Make default snapshot fast

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-dashboard-rubric.sh
- tests/run-cli-structure.sh
- python3 -m py_compile adapters/web/server.py

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
