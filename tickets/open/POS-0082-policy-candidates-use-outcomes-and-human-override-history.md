---
id: POS-0082
title: Policy candidates use outcomes and human override history
status: in-review
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T14:45:38Z
claim_ref: refs/palari/claims/POS-0082
claim_heartbeat_at: 2026-06-15T14:45:38Z
claim_expires_at: 2026-06-15T14:50:38Z
allowed_paths:
  - adapters/planning/policy_candidates.py
  - contracts/policy-acceptance.md
  - contracts/outcomes.md
  - tests/run-policy-candidates.sh
  - tests/run-outcomes.sh
  - tickets/open/POS-0082-policy-candidates-use-outcomes-and-human-override-history.md
  - reports/POS-0082-technical-report.md
  - reports/POS-0082-reviewer-note.md
  - reports/human/POS-0082-human-report.md
  - reports/evidence/POS-0082/**
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
  - ./tests/run-policy-candidates.sh
  - ./tests/run-outcomes.sh
target_branch: main
branch: ticket/POS-0082
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0082 Policy candidates use outcomes and human override history

## Goal

Make simulation-only policy candidate recommendations use outcome success,
rollback/failure, and human override signals in addition to repeated low-risk
decision shape.

## Scope

- Improve `policy candidates` scoring and reasons for R0-R2 candidate groups.
- Carry approval, override, outcome success, rollback/failure, and evidence
  signal summaries into text and JSON output.
- Reduce confidence when humans override recommendations or outcomes fail.
- Keep candidates simulation-only and conservative.
- Add focused test coverage for successful, overridden, failed, rollback, and
  R3+ exclusion paths.

## Acceptance

- Candidates remain limited to R0-R2 by default.
- Candidate output includes approval rate, override rate, outcome success rate,
  rollback/failure rate, evidence signal, confidence, and human-readable reason.
- Any override or invalidated/failed/rollback outcome reduces confidence.
- R3+ candidates are not emitted by default.
- No policy files are created or activated.
- Path and risk rules are respected.

## Verification

- ./tests/run-policy-candidates.sh
- ./tests/run-outcomes.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement real policy acceptance.
- Do not create policy artifacts automatically.
- Do not change decision lifecycle, outcome lifecycle, HGL scoring, broker
  behavior, authority rules, dependencies, secrets, runtime state, or side
  effects.

### Definition Of Done

- Policy candidate output is more evidence-aware while remaining conservative,
  read-only, and simulation-only.

### Evidence Required

- Text and JSON policy-candidate output.
- Focused policy-candidate and outcome test output.
- Ticket lint, report lint, scope check, CI, and evidence score output.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
