---
id: POS-0034
title: Merge-gate CI compatibility fixes
status: accepted
risk: R2
priority: P2
stream: infra
claimed_by: codex
claimed_at: 2026-06-09T18:38:22Z
claim_ref: refs/palari/claims/POS-0034
claim_heartbeat_at: 2026-06-11T06:19:54Z
claim_expires_at: 2026-06-11T06:24:54Z
allowed_paths:
  - .github/workflows/palari.yml
  - lib/palari/adapters_snapshot.bash
  - lib/palari/ci_accept.bash
  - tests/run-github-ci.sh
  - tests/run-golden.sh
  - tests/run-agent-wrapper.sh
  - tickets/open/POS-0034-*.md
  - tickets/closed/POS-0034-*.md
  - reports/POS-0034-technical-report.md
  - reports/POS-0034-reviewer-note.md
  - reports/evidence/POS-0034/**
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
  - tests/run-github-ci.sh
  - tests/run-golden.sh
  - tests/run-agent-wrapper.sh
  - bash -n bin/palari lib/palari/*.bash
  - git diff --check
target_branch: main
branch: ticket/POS-0034
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0034
accepted_by: founder
accepted_at: 2026-06-11T06:21:38Z
created: 2026-06-09
updated: 2026-06-11
---

# POS-0034 Merge-gate CI compatibility fixes

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-github-ci.sh
- tests/run-golden.sh
- tests/run-agent-wrapper.sh
- bash -n bin/palari lib/palari/*.bash
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
