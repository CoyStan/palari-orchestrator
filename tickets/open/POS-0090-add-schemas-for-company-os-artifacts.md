---
id: POS-0090
title: Add schemas for company OS artifacts
status: in-review
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T16:11:56Z
claim_ref: refs/palari/claims/POS-0090
claim_heartbeat_at: 2026-06-16T13:43:19Z
claim_expires_at: 2026-06-16T13:48:19Z
allowed_paths:
  - schemas/**
  - contracts/**
  - tests/**
  - tickets/open/POS-0090-add-schemas-for-company-os-artifacts.md
  - reports/POS-0090-technical-report.md
  - reports/POS-0090-reviewer-note.md
  - reports/human/POS-0090-human-report.md
  - reports/evidence/POS-0090/**
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
  - ./bin/palari workflow lint
  - ./bin/palari human lint
  - ./bin/palari policy lint
  - ./bin/palari outcome lint
  - ./tests/run-company-os-schemas.sh
target_branch: main
branch: ticket/POS-0090
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-16
---

# POS-0090 Add schemas for company OS artifacts

## Goal

Add JSON schemas for the core company OS artifacts so future typed validation
can grow from documented, versioned machine contracts without breaking the
current Markdown/frontmatter interface.

## Scope

- Add or update JSON schemas under `schemas/` for workflow, human, policy,
  outcome, broker observation, and company OS snapshot artifacts.
- Update contracts where needed to describe the schemas and compatibility
  boundary.
- Add focused tests that inspect representative fixtures against the schemas
  using stdlib-only validation when third-party schema validators are absent.

## Acceptance

- Schemas document current fields and planned fields.
- Lint can remain Bash/Python for now.
- Representative fixtures are validated against schemas when dependencies are
  available, with deterministic stdlib fallback checks for the schema contract.
- Existing artifacts keep working; no migration or breaking artifact rewrite is
  included.
- Path and risk rules are respected.

## Verification

- ./bin/palari workflow lint
- ./bin/palari human lint
- ./bin/palari policy lint
- ./bin/palari outcome lint
- ./tests/run-company-os-schemas.sh

## Ticket Completion Contract

### Non-Goals

- Do not rewrite workflow, human, policy, outcome, broker, or snapshot runtime
  parsers.
- Do not migrate existing artifacts.
- Do not add runtime dependencies or lockfiles.
- Do not change policy acceptance, broker behavior, HGL scoring, workflow
  lifecycle, authority, secrets, deployment, or side effects.

### Definition Of Done

- The requested schemas exist and tests prove their expected shape against
  representative company OS fixtures.
- Existing workflow, human, policy, and outcome lints still pass.

### Evidence Required

- Technical report, reviewer note, and human report.
- CI evidence bundle under `reports/evidence/POS-0090/`.
- Output from ticket lint, report lint, scope check, and evidence score.

### Expansion Rules

- Stop if implementation would require parser rewrites, artifact migrations,
  dependency changes, or authority/runtime behavior changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
