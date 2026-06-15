---
id: POS-0086
title: Add decision inbox grouped by risk skill and HGL
status: open
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - adapters/planning/**
  - lib/palari/**
  - tests/run-decisions.sh
  - tests/run-workflow-planning.sh
  - tickets/open/POS-0086-add-decision-inbox-grouped-by-risk-skill-and-hgl.md
  - reports/POS-0086-technical-report.md
  - reports/POS-0086-reviewer-note.md
  - reports/human/POS-0086-human-report.md
  - reports/evidence/POS-0086/**
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
  - ./tests/run-decisions.sh
  - ./tests/run-workflow-planning.sh
target_branch: main
branch: ticket/POS-0086
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0086 Add decision inbox grouped by risk skill and HGL

## Goal

Add a read-only decision inbox that groups expected workflow decisions and open
decision artifacts by risk, required skill, and estimated HGL.

## Scope

- Add `palari decide inbox` and `palari decide inbox --json`.
- Include workflow expected decisions and open decision artifacts.
- Sort recommended work by highest risk, then highest HGL.
- Include policy-candidate summary context without activating policies.
- Add focused tests for text/JSON output and read-only behavior.

## Acceptance

- Inbox includes workflow expected decisions and open decision artifacts.
- Inbox groups/sorts by risk and HGL.
- Inbox reports required skills, coverage status, eligible humans, and policy
  candidate counts.
- Inbox does not create, record, move, or accept decisions.
- Path and risk rules are respected.

## Verification

- ./tests/run-decisions.sh
- ./tests/run-workflow-planning.sh

## Ticket Completion Contract

### Non-Goals

- Do not create or record decisions automatically.
- Do not change decision lifecycle, workflow lifecycle, HGL scoring, policy
  acceptance, broker behavior, dependencies, secrets, runtime state, or side
  effects.

### Definition Of Done

- The inbox command and focused tests pass with text and JSON output.

### Evidence Required

- Text and JSON inbox command output.
- Focused decision and workflow-planning test output.
- Ticket lint, report lint, scope check, CI, and evidence score output.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
