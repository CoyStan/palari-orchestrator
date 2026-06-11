---
id: POS-0041
title: Evidence quality scoring
status: accepted
risk: R2
priority: P1
stream: autonomy
claimed_by: codex
claimed_at: 2026-06-10T22:12:28Z
claim_ref: refs/palari/claims/POS-0041
claim_heartbeat_at: 2026-06-11T05:40:42Z
claim_expires_at: 2026-06-11T05:45:42Z
allowed_paths:
  - bin/palari
  - lib/palari/evidence_quality.bash
  - docs/autonomy/evidence-quality-scoring.md
  - tests/run-evidence-quality.sh
  - tickets/open/POS-0041-*.md
  - tickets/closed/POS-0041-*.md
  - reports/POS-0041-technical-report.md
  - reports/POS-0041-reviewer-note.md
  - reports/evidence/POS-0041/**
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
verification:
  - tests/run-evidence-quality.sh
  - bash -n bin/palari lib/palari/*.bash tests/run-evidence-quality.sh
  - git diff --check
target_branch: main
branch: ticket/POS-0041
worktree: /home/quetza/palari-orchestrator-worktrees/POS-0041/../palari-orchestrator-worktrees/POS-0041
accepted_by: quetza
accepted_at: 2026-06-11T05:40:43Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0041 Evidence quality scoring

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-evidence-quality.sh
- bash -n bin/palari lib/palari/*.bash tests/run-evidence-quality.sh
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
