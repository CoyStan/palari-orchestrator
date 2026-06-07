---
id: POS-0011
title: README presentation refresh
status: accepted
risk: R1
priority: P2
stream: presentation
claimed_by: founder-closeout
claimed_at: 2026-06-07T09:17:14Z
claim_ref: refs/palari/claims/POS-0011
claim_heartbeat_at: 2026-06-07T09:17:14Z
claim_expires_at: 2026-06-07T13:17:14Z
allowed_paths:
  - README.md
  - assets/readme/**
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
verification:
  - grep -q 'Repo-native governance for AI coding agents' README.md
  - test -s assets/readme/palari-orchestrator-hero-general.png
  - test -s assets/readme/palari-console-preview.png
  - git diff --check "${GITHUB_BASE_REF:-origin/main}"...HEAD
  - grep -q 'assets/readme/palari-orchestrator-hero-general.png' README.md
  - grep -q 'assets/readme/palari-console-preview.png' README.md
target_branch: main
branch: ticket/POS-0011
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0011
accepted_by: founder
accepted_at: 2026-06-07T09:25:30Z
created: 2026-06-06
updated: 2026-06-07
---

# POS-0011 README Presentation Refresh

## Goal

Make the public README easier for a busy reader to understand and refresh the
README artwork so the project presents Palari Orchestrator as calm,
repo-governed agent work.

## Scope

- Tighten the README opening and first-screen framing.
- Replace the README hero image with a Palari-specific workflow visual.
- Replace the console preview with a clean dashboard screenshot.
- Add only this governance ticket for the presentation work.

## Acceptance

- The README states the value, audience, workflow, and boundaries before the
  deeper command reference.
- The hero image communicates scoped work, evidence, review, and human
  acceptance without fake product text.
- The console preview shows a stable, healthy dashboard state.
- All changed paths remain inside the presentation ticket scope.

## Verification

- grep -q 'Repo-native governance for AI coding agents' README.md
- test -s assets/readme/palari-orchestrator-hero-general.png
- test -s assets/readme/palari-console-preview.png
- git diff --check "${GITHUB_BASE_REF:-origin/main}"...HEAD
- grep -q 'assets/readme/palari-orchestrator-hero-general.png' README.md
- grep -q 'assets/readme/palari-console-preview.png' README.md

## Ticket Completion Contract

### Non-Goals

- Do not change Palari CLI behavior.
- Do not add new adapters, tests, or product-specific app preferences.
- Do not alter GitHub ruleset or CI policy.

### Definition Of Done

- README presentation changes are governed by a source-controlled ticket and
  pass the ticket verification commands.

### Evidence Required

- Palari CI evidence for POS-0011.

### Expansion Rules

- Stop if the work requires product code changes or changes outside
  `README.md`, `assets/readme/**`, or `tickets/**`.

### Final Review Gate

- Reviewer checks that the README reads clearly for a busy first-time visitor
  and that the images match the Palari governance tone.
