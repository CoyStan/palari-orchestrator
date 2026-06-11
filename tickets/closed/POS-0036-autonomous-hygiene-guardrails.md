---
id: POS-0036
title: Autonomous hygiene guardrails
status: accepted
risk: R2
priority: P1
stream: infrastructure
claimed_by: codex
claimed_at: 2026-06-10T20:11:59Z
claim_ref: refs/palari/claims/POS-0036
claim_heartbeat_at: 2026-06-11T06:57:29Z
claim_expires_at: 2026-06-11T07:02:29Z
allowed_paths:
  - .github/workflows/**
  - .gitignore
  - README.md
  - adapters/web/static/app.js
  - bin/palari
  - lib/palari/**
  - palari.config.yaml
  - schemas/**
  - tests/**
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
required_reports:
  - POS-0036-technical-report.md
verification:
  - tests/run-hygiene.sh
  - tests/run-cli-structure.sh
  - tests/run-adoption.sh
  - tests/run-dashboard-rubric.sh
  - node --check adapters/web/static/app.js
  - python3 -m py_compile adapters/web/server.py
  - git diff --check
target_branch: main
branch: ticket/POS-0036
worktree: /home/quetza/palari-orchestrator-worktrees/autonomous-hygiene/../palari-orchestrator-worktrees/POS-0036
accepted_by: founder
accepted_at: 2026-06-11T06:59:28Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0036 Autonomous hygiene guardrails

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-hygiene.sh
- tests/run-cli-structure.sh
- tests/run-adoption.sh
- tests/run-dashboard-rubric.sh
- node --check adapters/web/static/app.js
- python3 -m py_compile adapters/web/server.py
- git diff --check

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
