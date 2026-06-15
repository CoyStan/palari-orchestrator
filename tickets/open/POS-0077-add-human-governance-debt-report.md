---
id: POS-0077
title: Add Human Governance Debt report
status: in-review
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T13:56:04Z
claim_ref: refs/palari/claims/POS-0077
claim_heartbeat_at: 2026-06-15T13:56:04Z
claim_expires_at: 2026-06-15T14:01:04Z
allowed_paths:
  - adapters/planning/**
  - lib/palari/**
  - contracts/human-governance-load.md
  - tests/run-human-governance-load.sh
  - tests/run-company-os-snapshot.sh
  - tickets/open/POS-0077-add-human-governance-debt-report.md
  - tickets/closed/POS-0077-add-human-governance-debt-report.md
  - reports/POS-0077-technical-report.md
  - reports/POS-0077-reviewer-note.md
  - reports/human/POS-0077-human-report.md
  - reports/evidence/POS-0077/**
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
  - ./tests/run-human-governance-load.sh
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0077
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0077 Add Human Governance Debt report

## Goal

Add a deterministic, read-only Human Governance Debt report for active company
OS workflows.

## Scope

- `palari burden debt [--json]` command wiring.
- Planning adapter logic for debt detection and prioritization.
- Snapshot summary reference to the debt report.
- Human Governance Load contract and focused tests.
- Ticket reports and evidence.

## Acceptance

- `palari burden debt` prints a readable debt level, debt items, and highest
  leverage fix.
- `palari burden debt --json` returns deterministic structured data.
- The report covers missing skills, high-risk bottlenecks, weak evidence,
  configured R5 human-quorum coverage gaps, capacity pressure, and policy-candidate
  opportunities where current repo artifacts expose them.
- Snapshot includes a compact debt summary.
- The report remains read-only and does not mutate workflows, humans, tickets,
  policies, outcomes, evidence, weights, or side effects.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-company-os-snapshot.sh

## Ticket Completion Contract

### Non-Goals

- Do not recalibrate HGL weights.
- Do not create, accept, or activate policies.
- Do not create human profiles, workflows, tickets, decisions, or outcomes.
- Do not add external integrations or broker side effects.

### Definition Of Done

- Operators can inspect current governance debt from the CLI and snapshot
  without changing repo-native state.

### Evidence Required

- Technical report, reviewer note, human report, verification log, CI manifest,
  JUnit, SARIF, and evidence score.

### Expansion Rules

- Stop if implementation requires new authority semantics, policy acceptance,
  employee productivity metrics, or non-read-only behavior.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
