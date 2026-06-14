---
id: PLN-0001
title: Add workflow planning and autonomy ceiling
status: accepted
risk: R4
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T23:03:07Z
claim_ref: refs/palari/claims/PLN-0001
claim_heartbeat_at: 2026-06-14T23:10:46Z
claim_expires_at: 2026-06-14T23:15:46Z
allowed_paths:
  - contracts/**
  - docs/autonomy/**
  - lib/palari/**
  - adapters/planning/**
  - bin/palari
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/PLN-0001*
  - tickets/closed/PLN-0001*
  - reports/**
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
requires_human_confirmation: true
requires_review: true
verification:
  - ./tests/run-workflow-planning.sh
  - ./tests/run-queue-dry-run.sh
  - ./tests/run-human-governance-load.sh
target_branch: main
branch: ticket/PLN-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-14T23:11:04Z
created: 2026-06-14
updated: 2026-06-14
---

# PLN-0001 Add workflow planning and autonomy ceiling

## Goal

Add a read-only workflow planner that combines workflow artifacts, HGL scoring,
human coverage, launch gates, and autonomy ceilings.

## Scope

- Add `palari workflow plan WF-ID [--json]`.
- Compose workflow frontmatter with the HGL scorer and active human coverage.
- Show AI modes that may proceed, modes that remain blocked, required skills,
  missing skills, bottlenecks, and recommended next actions.
- Document the read-only planner boundary.
- Add focused regression tests for text output, JSON output, red/yellow gates,
  and non-mutation.

## Acceptance

- `palari workflow plan WF-ID` prints a human-readable plan.
- `palari workflow plan WF-ID --json` prints deterministic machine-readable
  output.
- The planner uses HGL and active human coverage for launch gate and autonomy
  explanations.
- The planner does not claim tickets, create worktrees, run agents, accept
  work, activate policies, write broker evidence, push, merge, deploy, or call
  external systems.
- Path and risk rules are respected.

## Verification

- ./tests/run-workflow-planning.sh
- ./tests/run-queue-dry-run.sh
- ./tests/run-human-governance-load.sh

## Ticket Completion Contract

### Non-Goals

- Do not add multiple workflow execution modes.
- Do not mutate `palari run --dry-run` semantics.
- Do not add policy simulation, policy acceptance, broker behavior, snapshots,
  dashboards, outcomes, credentials, network calls, or external writes.

### Definition Of Done

- Workflow planner command is wired into `palari workflow`.
- Text and JSON output include launch gate, autonomy ceiling, allowed/blocked
  modes, HGL, decision counts, required skills, missing skills, bottlenecks,
  and recommended next actions.
- Focused tests prove yellow and red workflows and read-only behavior.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report for the R4 human gate.
- Focused planner test output.
- CI evidence bundle for PLN-0001.

### Expansion Rules

- Stop if this requires lifecycle mutation, policy activation, broker side
  effects, snapshot/dashboard work, or non-stdlib dependencies.

### Final Review Gate

- Reviewer confirms planner output is read-only, deterministic, scope-bounded,
  and composed from workflow/HGL/human artifacts before recommending accept,
  reopen, or needs-human.
