---
id: POS-0040
title: Autonomous queue-runner dry-run spec
status: accepted
risk: R1
priority: P1
stream: autonomy
claimed_by: codex
claimed_at: 2026-06-10T22:08:33Z
claim_ref: refs/palari/claims/POS-0040
claim_heartbeat_at: 2026-06-11T05:36:06Z
claim_expires_at: 2026-06-11T05:41:06Z
allowed_paths:
  - docs/autonomy/queue-runner-dry-run.md
  - tests/run-autonomy-spec.sh
  - tickets/open/POS-0040-*.md
  - tickets/closed/POS-0040-*.md
  - reports/POS-0040-technical-report.md
  - reports/POS-0040-reviewer-note.md
  - reports/evidence/POS-0040/**
forbidden_paths:
  - .env
  - .env.*
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-autonomy-spec.sh
  - bash -n tests/run-autonomy-spec.sh
  - git diff --check
target_branch: main
branch: ticket/POS-0040
worktree:
accepted_by: quetza
accepted_at: 2026-06-11T05:36:07Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0040 Autonomous queue-runner dry-run spec

## Goal

Define a conservative dry-run specification for a future `palari run --until
blocked` queue runner so Palari can plan long-running autonomous work before it
is allowed to spawn agents or mutate lifecycle state.

## Scope

- Add `docs/autonomy/queue-runner-dry-run.md`.
- Add a focused shell test that locks the safety requirements in the spec.
- Do not implement the runner command yet.

## Acceptance

- The spec defines dry-run inputs, outputs, stop reasons, ticket selection,
  evidence expectations, and safety boundaries.
- The spec says dry-run mode is read-only and cannot claim, accept, merge,
  push, deploy, or spawn agents.
- The spec identifies the transition from prompt generation and Founder Inbox
  to a future supervised runner.

## Verification

- tests/run-autonomy-spec.sh
- bash -n tests/run-autonomy-spec.sh
- git diff --check

## Ticket Completion Contract

### Non-Goals

- Do not implement `palari run`.
- Do not add executor integration.
- Do not mutate tickets or acceptance authority.
- Do not depend on POS-0037, POS-0038, or POS-0039 being accepted.

### Definition Of Done

- A future implementer can build `palari run --dry-run --until blocked` from
  the spec without guessing authority boundaries.

### Evidence Required

- POS-0040 technical report.
- Spec test output.
- Palari CI evidence under `reports/evidence/POS-0040/`.

### Expansion Rules

- Stop if implementation would require actual agent execution, lifecycle
  mutation, acceptance, merge, push, deploy, credentials, or production access.

### Final Review Gate

- Reviewer checks the dry-run spec is conservative, implementable, and does not
  overgrant autonomy.
