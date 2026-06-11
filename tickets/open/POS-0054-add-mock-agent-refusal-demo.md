---
id: POS-0054
title: Add mock-agent refusal demo
status: open
risk: R2
priority: P1
stream: demo
serves_goal: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - lib/palari/demo.bash
  - lib/palari/agents_review_scope.bash
  - README.md
  - tests/run-demo.sh
  - tests/run-agent-mock.sh
  - CHANGELOG.md
  - tickets/open/POS-0054*
  - tickets/closed/POS-0054*
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
  - tests/run-demo.sh
  - tests/run-agent-mock.sh
  - shellcheck -x bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh
target_branch: main
branch: ticket/POS-0054
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0054 Add mock-agent refusal demo

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-demo.sh
- tests/run-agent-mock.sh
- shellcheck -x bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh

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
