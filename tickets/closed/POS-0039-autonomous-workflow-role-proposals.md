---
id: POS-0039
title: Autonomous workflow role proposals
status: accepted
risk: R2
priority: P1
stream: roles
claimed_by: codex
claimed_at: 2026-06-10T22:04:50Z
claim_ref: refs/palari/claims/POS-0039
claim_heartbeat_at: 2026-06-11T05:31:22Z
claim_expires_at: 2026-06-11T05:36:22Z
allowed_paths:
  - roles/proposed/**
  - docs/autonomy/**
  - tests/run-autonomy-roles.sh
  - tests/run-roles.sh
  - tickets/open/POS-0039-*.md
  - tickets/closed/POS-0039-*.md
  - reports/POS-0039-technical-report.md
  - reports/POS-0039-reviewer-note.md
  - reports/evidence/POS-0039/**
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
  - tests/run-autonomy-roles.sh
  - ./bin/palari role lint
  - bash -n tests/run-autonomy-roles.sh
  - git diff --check
target_branch: main
branch: ticket/POS-0039
worktree:
accepted_by: quetza
accepted_at: 2026-06-11T05:31:23Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0039 Autonomous workflow role proposals

## Goal

Add proposed operating roles for long-running founder/operator workflows so
Palari can model Product, Design, QA, Release, and Autonomy Coordinator lenses
without silently granting new active authority.

## Scope

- Add proposed role files under `roles/proposed/`.
- Add a short autonomy role guide under `docs/autonomy/`.
- Add a focused test that verifies the proposed roles are present, lint-clean,
  and still non-accepting.
- Do not move proposed roles to active status.

## Acceptance

- Proposed roles exist for product, design, QA, release, and autonomy
  coordination.
- `./bin/palari role lint` passes.
- Proposed roles cannot accept work and do not bypass tickets, evidence,
  review, merge, deploy, secrets, or production gates.
- Documentation explains when each role should be used in long-running agent
  workflows.

## Verification

- tests/run-autonomy-roles.sh
- ./bin/palari role lint
- bash -n tests/run-autonomy-roles.sh
- git diff --check

## Ticket Completion Contract

### Non-Goals

- Do not adopt or activate the proposed roles.
- Do not change root, active role, or acceptance authority.
- Do not implement an autonomous runner.
- Do not add frontend/dashboard behavior.

### Definition Of Done

- A founder can review the proposed roles and decide which ones to adopt for
  future autonomous workflow tickets.

### Evidence Required

- POS-0039 technical report.
- Role lint output.
- Palari CI evidence under `reports/evidence/POS-0039/`.

### Expansion Rules

- Stop if role activation, acceptance authority, production access, or
  destructive automation would be required.

### Final Review Gate

- Reviewer checks role authority boundaries, proposed-only status, and no
  acceptance capability before human adoption decisions.
