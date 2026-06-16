---
id: POS-0085
title: Expand company OS demo across growth support and engineering
status: accepted
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T14:53:30Z
claim_ref: refs/palari/claims/POS-0085
claim_heartbeat_at: 2026-06-16T07:11:19Z
claim_expires_at: 2026-06-16T07:16:19Z
allowed_paths:
  - lib/palari/demo.bash
  - tests/run-company-os-demo.sh
  - tests/run-company-os-snapshot.sh
  - README.md
  - assets/readme/**
  - tickets/open/POS-0085-expand-company-os-demo-across-growth-support-and-engineering.md
  - reports/POS-0085-technical-report.md
  - reports/POS-0085-reviewer-note.md
  - reports/human/POS-0085-human-report.md
  - reports/evidence/POS-0085/**
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
  - ./bin/palari demo --company-os --force
  - ./tests/run-company-os-demo.sh
  - ./tests/run-company-os-snapshot.sh
target_branch: main
branch: ticket/POS-0085
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-16T07:11:51Z
created: 2026-06-15
updated: 2026-06-16
---

# POS-0085 Expand company OS demo across growth support and engineering

## Goal

Expand the company OS demo so it shows multiple workflows with distinct
governance states: green/high-autonomy support work, yellow/conditional growth
work, and red/simulation-only engineering or privacy-risk work.

## Scope

- Update `palari demo --company-os --force` fixtures.
- Add or adjust demo assertions for workflows, snapshot state, broker evidence,
  outcomes, and policy candidates.
- Keep the demo deterministic and side-effect-free.
- Update README/readme assets only if they need to describe the richer demo.

## Acceptance

- Demo creates growth, support, and engineering workflows with green/yellow/red
  governance outcomes.
- Snapshot reflects all demo fixtures.
- Demo includes at least one mock broker observation, one outcome, and one
  low-risk policy candidate.
- `workflow plan` for each demo workflow gives distinct useful recommendations.
- Path and risk rules are respected.

## Verification

- ./bin/palari demo --company-os --force
- ./tests/run-company-os-demo.sh
- ./tests/run-company-os-snapshot.sh

## Ticket Completion Contract

### Non-Goals

- Do not add real broker side effects.
- Do not change HGL scoring, policy acceptance, broker permissions, authority
  rules, dependencies, secrets, runtime state, or deployment.
- Do not redesign the full operator dashboard; this is demo fixture breadth.

### Definition Of Done

- Demo and snapshot tests prove the richer company OS fixture set.

### Evidence Required

- Demo command output.
- Company OS demo and snapshot test output.
- Ticket lint, report lint, scope check, CI, and evidence score output.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
