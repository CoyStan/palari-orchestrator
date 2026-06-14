---
id: HGL-0001
title: Add Human Governance Load scorer
status: claimed
risk: R4
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T22:50:04Z
claim_ref: refs/palari/claims/HGL-0001
claim_heartbeat_at: 2026-06-14T22:50:04Z
claim_expires_at: 2026-06-14T22:55:04Z
allowed_paths:
  - contracts/**
  - lib/palari/**
  - adapters/planning/**
  - bin/palari
  - tests/**
  - reports/planning/**
  - STATE.md
  - CHANGELOG.md
  - README.md
  - tickets/open/HGL-0001*
  - tickets/closed/HGL-0001*
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
  - ./tests/run-human-governance-load.sh
  - ./tests/run-workflows.sh
  - ./tests/run-human-governance.sh
target_branch: main
branch: ticket/HGL-0001
worktree: 
accepted_by:
accepted_at:
created: 2026-06-14
updated: 2026-06-14
---

# HGL-0001 Add Human Governance Load scorer

## Goal

Add a deterministic, read-only Human Governance Load scorer for workflow
artifacts, plus human skill coverage output.

## Scope

- Add the HGL scoring adapter under `adapters/planning/`.
- Add the CLI wrapper and dispatch for `palari burden score`.
- Expose `palari human coverage` from the human governance command group.
- Document the scoring boundary in contracts, README, state, and changelog.
- Add focused regression coverage for scoring, skill gaps, bottlenecks,
  launch gates, autonomy ceilings, and JSON output.

## Acceptance

- `palari burden score WF-ID` prints deterministic text output.
- `palari burden score WF-ID --json` prints machine-readable JSON.
- `palari human coverage WF-ID --json` reports required skills from a
  workflow against active human profiles.
- Missing R3/R4/R5 coverage is visible and fails conservative launch gates.
- No lifecycle state, workflow state, ticket state, policies, broker actions,
  credentials, or external systems are mutated.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-workflows.sh
- ./tests/run-human-governance.sh

## Ticket Completion Contract

### Non-Goals

- Do not add workflow planning beyond scoring and coverage.
- Do not add policy simulation or policy acceptance.
- Do not add broker behavior, external writes, network calls, or credentials.
- Do not change ticket acceptance, ForgeGate, executor, or model routing
  behavior.

### Definition Of Done

- HGL scoring and coverage commands are wired into `bin/palari`.
- Scoring implements the roadmap's initial risk/novelty/ambiguity/
  irreversibility/context/skill-scarcity/evidence weights.
- Text and JSON output are deterministic.
- Reports, human note, CI evidence, and scope checks are present.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report for the R4 human gate.
- Focused HGL test output.
- CI evidence bundle for HGL-0001.

### Expansion Rules

- Stop if the work needs policy activation, broker side effects, token/secret
  handling, acceptance mutation, or a new risk tier.
- Stop if HGL scoring requires non-stdlib dependencies.

### Final Review Gate

- Reviewer confirms this is read-only scoring/coverage, verifies the deterministic
  formula and launch-gate behavior, checks scope evidence, and recommends
  accept, reopen, or needs-human.
