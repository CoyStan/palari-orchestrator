---
id: POS-0078
title: Add minimum viable human company planner
status: in-review
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T14:07:13Z
claim_ref: refs/palari/claims/POS-0078
claim_heartbeat_at: 2026-06-15T14:07:13Z
claim_expires_at: 2026-06-15T14:12:13Z
allowed_paths:
  - adapters/planning/**
  - lib/palari/**
  - contracts/human-governance.md
  - contracts/company-ai-os.md
  - tests/run-human-governance.sh
  - tests/run-company-os-snapshot.sh
  - tickets/open/POS-0078-add-minimum-viable-human-company-planner.md
  - tickets/closed/POS-0078-add-minimum-viable-human-company-planner.md
  - reports/POS-0078-technical-report.md
  - reports/POS-0078-reviewer-note.md
  - reports/human/POS-0078-human-report.md
  - reports/evidence/POS-0078/**
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
  - ./tests/run-human-governance.sh
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0078
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0078 Add minimum viable human company planner

## Goal

Add a deterministic, read-only minimum viable human company planner for active
workflows.

## Scope

- `palari human org-plan [--json]` command wiring.
- Planning adapter logic for deriving required roles/skills from active
  workflow expected decisions.
- Human/company OS contracts and focused tests.
- Ticket reports and evidence.

## Acceptance

- `palari human org-plan` prints required governance roles/skills for active
  workflows.
- `palari human org-plan --json` returns deterministic structured data.
- The planner identifies missing coverage, thin single-human coverage, and
  concentration risk.
- Recommendations are derived from active workflow decisions, not generic
  headcount.
- The planner is read-only and does not create profiles, adopt humans, mutate
  workflows, change capacity, accept work, or grant authority.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance.sh
- ./tests/run-company-os-snapshot.sh

## Ticket Completion Contract

### Non-Goals

- Do not create or adopt human profiles.
- Do not change HGL scoring, capacity, authority, acceptance, policies, broker
  behavior, external integrations, runtime state, secrets, dependencies, or
  deployment.

### Definition Of Done

- Operators can inspect the minimum viable human company shape needed by active
  workflows without changing repo-native state.

### Evidence Required

- Technical report, reviewer note, human report, verification log, CI manifest,
  JUnit, SARIF, and evidence score.

### Expansion Rules

- Stop if implementation requires human-profile mutation, new authority
  semantics, employee productivity metrics, or non-read-only behavior.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
