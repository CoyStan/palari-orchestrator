---
id: POS-0080
title: Outcome records include metric and governance impact
status: in-review
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T14:20:31Z
claim_ref: refs/palari/claims/POS-0080
claim_heartbeat_at: 2026-06-15T14:20:31Z
claim_expires_at: 2026-06-15T14:25:31Z
allowed_paths:
  - lib/palari/outcomes.bash
  - contracts/outcomes.md
  - templates/**
  - adapters/planning/**
  - tests/run-outcomes.sh
  - tests/run-policy-candidates.sh
  - tickets/open/POS-0080-outcome-records-include-metric-and-governance-impact.md
  - tickets/closed/POS-0080-outcome-records-include-metric-and-governance-impact.md
  - reports/POS-0080-technical-report.md
  - reports/POS-0080-reviewer-note.md
  - reports/human/POS-0080-human-report.md
  - reports/evidence/POS-0080/**
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
  - ./bin/palari outcome lint
  - ./tests/run-outcomes.sh
  - ./tests/run-policy-candidates.sh
target_branch: main
branch: ticket/POS-0080
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0080 Outcome records include metric and governance impact

## Goal

Expand outcome artifacts so they can record metric impact and governance
impact while remaining optional, backward-compatible, and read-only for future
learning surfaces.

## Scope

- Outcome artifact creation and lint validation.
- Outcome template and contract.
- Policy candidate linked-outcome summaries.
- Focused outcome and policy-candidate tests.
- Ticket reports and evidence.

## Acceptance

- New outcome records include optional metric and governance-impact fields.
- Outcome lint validates populated risk, integer, decimal, boolean, and
  review-outcome fields.
- Policy candidates can carry successful linked outcome counts and outcome
  impact metadata.
- Existing outcome records remain compatible.
- No HGL weights, policies, acceptance, broker behavior, authority, or side
  effects change automatically.
- Path and risk rules are respected.

## Verification

- ./bin/palari outcome lint
- ./tests/run-outcomes.sh
- ./tests/run-policy-candidates.sh

## Ticket Completion Contract

### Non-Goals

- Do not recalibrate HGL.
- Do not automatically create or activate policies.
- Do not change outcome lifecycle, acceptance, broker behavior, external
  integrations, runtime state, secrets, dependencies, or deployment.

### Definition Of Done

- Outcomes can store predicted/actual metric and governance impact for later
  read-only policy/HGL learning.

### Evidence Required

- Technical report, reviewer note, human report, verification log, CI manifest,
  JUnit, SARIF, and evidence score.

### Expansion Rules

- Stop if implementation requires automatic policy activation, HGL mutation,
  real side effects, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
