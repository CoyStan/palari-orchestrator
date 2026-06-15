---
id: SEC-0001
title: Add secure governance doctor
status: accepted
risk: R5
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T00:19:47Z
claim_ref: refs/palari/claims/SEC-0001
claim_heartbeat_at: 2026-06-15T00:31:58Z
claim_expires_at: 2026-06-15T00:36:58Z
allowed_paths:
  - contracts/**
  - lib/palari/**
  - gate/**
  - palari.config.yaml
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/SEC-0001*
  - tickets/closed/SEC-0001*
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
  - ./tests/run-secure-doctor.sh
  - ./tests/run-gate.sh
  - ./tests/run-gate-kernel.sh
target_branch: main
branch: ticket/SEC-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T00:32:19Z
created: 2026-06-15
updated: 2026-06-15
---

# SEC-0001 Add secure governance doctor

## Goal

Add a conservative local doctor that makes the repository's secure governance
posture visible without changing acceptance, broker, policy, or deployment
authority.

## Scope

- Add `palari doctor secure`.
- Add `palari doctor governance` as the same governance-posture view.
- Add conservative governance config defaults for R5 human approval, simulated
  policy acceptance, and disabled real broker side effects.
- Add focused regression coverage and reports.

## Acceptance

- The doctor is useful when ForgeGate is disabled or unavailable.
- The doctor distinguishes weak and stronger local governance posture.
- The doctor does not claim hosted branch protection is active unless it can be
  verified; this slice always reports that branch protection is not verified
  locally.
- The doctor fails no safer behavior silently: ForgeGate, broker, policy, R5,
  and branch-protection boundaries are all explicit in output.

## Verification

- ./tests/run-secure-doctor.sh
- ./tests/run-gate.sh
- ./tests/run-gate-kernel.sh

## Ticket Completion Contract

### Non-Goals

- Enabling ForgeGate globally.
- Verifying GitHub branch protection from local state.
- Enabling policy auto-acceptance.
- Enabling real broker side effects.
- Changing deploy, runtime, secrets, credentials, or hosted integrations.

### Definition Of Done

- `palari doctor secure` and `palari doctor governance` print posture,
  explicit boundary bullets, recommended modes, and local verification limits.
- Focused tests cover weak posture, stronger local posture, R5 missing config,
  and branch-protection non-overclaim.
- Existing gate tests still pass.

### Evidence Required

- Technical report with changed paths, verification, CI evidence, and residual
  risk notes.
- Reviewer note recommending accept/reopen/needs-human.
- Human report explaining the posture boundary in founder-readable terms.
- CI evidence bundle under `reports/evidence/SEC-0001/`.

### Expansion Rules

- Stop if this work needs remote GitHub API branch-protection verification.
- Stop if this work would enable ForgeGate, real broker side effects, policy
  acceptance authority, credentials, or hosted side effects.

### Final Review Gate

- Reviewer checks the doctor output for honest weak/stronger claims, no branch
  protection overclaim, unchanged authority boundaries, and passing evidence.
