---
id: POS-0076
title: Workflow plan includes human decision map
status: accepted
risk: R2
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T13:47:56Z
claim_ref: refs/palari/claims/POS-0076
claim_heartbeat_at: 2026-06-16T07:06:26Z
claim_expires_at: 2026-06-16T07:11:26Z
allowed_paths:
  - adapters/planning/workflow_plan.py
  - adapters/planning/hgl.py
  - contracts/workflows.md
  - contracts/human-governance-load.md
  - tests/run-workflow-planning.sh
  - tickets/open/POS-0076-workflow-plan-includes-human-decision-map.md
  - tickets/closed/POS-0076-workflow-plan-includes-human-decision-map.md
  - reports/POS-0076-technical-report.md
  - reports/POS-0076-reviewer-note.md
  - reports/human/POS-0076-human-report.md
  - reports/evidence/POS-0076/**
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
  - ./tests/run-workflow-planning.sh
  - ./tests/run-company-os-demo.sh
target_branch: main
branch: ticket/POS-0076
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-16T07:06:49Z
created: 2026-06-15
updated: 2026-06-16
---

# POS-0076 Workflow plan includes human decision map

## Goal

Add a read-only human decision map to workflow planning so operators can see
the specific human decisions that remain, not only aggregate R3/R4/R5 counts.

## Scope

- Workflow planner output and formatting.
- HGL/workflow contracts that define the planning surface.
- Focused workflow-planning tests.
- Ticket reports and evidence.

## Acceptance

- `workflow plan --json` includes `human_decision_map`.
- Text workflow plans include a `Human decision map:` section.
- Decision map rows sort by highest risk and then highest HGL.
- R5 decisions are clearly human-governed and do not imply policy acceptance.
- Path and risk rules are respected.

## Verification

- ./tests/run-workflow-planning.sh
- ./tests/run-company-os-demo.sh
- Disposable `WF-9004` demo smoke: run `demo --company-os --force`, then
  `workflow plan WF-9004` and `workflow plan WF-9004 --json`.

## Ticket Completion Contract

### Non-Goals

- Do not change HGL scoring, launch gate rules, human capacity rules, policy
  acceptance, broker behavior, external side effects, or artifact lifecycle.

### Definition Of Done

- Workflow plans expose specific human decision rows with coverage status,
  eligible humans, HGL score, and human-governance reasons.

### Evidence Required

- Technical report, reviewer note, verification log, CI manifest, and human
  report are present for review.

### Expansion Rules

- Stop if the implementation needs new artifact state, policy acceptance,
  broker execution, or authority model changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
