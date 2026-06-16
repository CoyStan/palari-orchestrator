---
id: POS-0087
title: Dashboard exposes company OS governance cards
status: accepted
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T15:16:01Z
claim_ref: refs/palari/claims/POS-0087
claim_heartbeat_at: 2026-06-16T07:13:23Z
claim_expires_at: 2026-06-16T07:18:23Z
allowed_paths:
  - adapters/web/**
  - adapters/snapshot/**
  - lib/palari/adapters_snapshot.bash
  - lib/palari/dashboard_snapshot.bash
  - assets/readme/**
  - tests/run-dashboard-rubric.sh
  - tests/run-company-os-snapshot.sh
  - tickets/open/POS-0087-dashboard-exposes-company-os-governance-cards.md
  - reports/POS-0087-technical-report.md
  - reports/POS-0087-reviewer-note.md
  - reports/human/POS-0087-human-report.md
  - reports/evidence/POS-0087/**
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
verification:
  - ./bin/palari web --check
  - ./tests/run-dashboard-rubric.sh
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0087
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-16T07:14:35Z
created: 2026-06-15
updated: 2026-06-16
---

# POS-0087 Dashboard exposes company OS governance cards

## Goal

Expose company OS governance as clear dashboard/check cards so operators can see
HGL, high-risk decisions, missing skills, bottlenecks, autonomy gates, policy
simulation status, broker posture, outcomes, and secure posture.

## Scope

- Add or extend dashboard/web-check snapshot data for company OS governance cards.
- Preserve existing snapshot data while adding explicit card labels/statuses.
- Update dashboard rubric and company OS snapshot tests.
- Update readme assets only if they need to mention the new cards.

## Acceptance

- Dashboard/web-check data does not hide red/yellow gates.
- Broker posture is clearly labeled mock/observed-only unless sandbox boundary exists.
- Policy posture is clearly labeled simulation-only.
- Cards cover HGL, R3/R4/R5 decisions, missing skills, bottlenecks, autonomy
  gates, policy candidates, broker posture, outcomes, and secure posture.
- Path and risk rules are respected.

## Verification

- ./bin/palari web --check
- ./tests/run-dashboard-rubric.sh
- ./tests/run-company-os-snapshot.sh

## Ticket Completion Contract

### Non-Goals

- Do not add product UI redesign.
- Do not change broker behavior, policy acceptance, HGL scoring, workflow
  lifecycle, dependencies, secrets, runtime state, deployment, or side effects.

### Definition Of Done

- Web/check snapshot and focused tests expose the governance card data.

### Evidence Required

- Web check output.
- Dashboard rubric and company OS snapshot test output.
- Ticket lint, report lint, scope check, CI, and evidence score output.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
