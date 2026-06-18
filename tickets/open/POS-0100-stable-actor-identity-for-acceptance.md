---
id: POS-0100
title: Stable actor identity for acceptance
status: claimed
risk: R5
priority: P1
stream: process
serves_goal:
model_hint:
claimed_by: Codex
claimed_at: 2026-06-18T00:58:59Z
claim_ref: refs/palari/claims/POS-0100
claim_heartbeat_at: 2026-06-18T05:47:41Z
claim_expires_at: 2026-06-18T05:52:42Z
allowed_paths:
  - lib/palari/ci_accept.bash
  - lib/palari/humans.bash
  - lib/palari/core.bash
  - schemas/palari.config.schema.json
  - contracts/authority-and-lifecycle.md
  - README.md
  - tests/palari_acceptance.bats
  - tests/run-human-governance.sh
  - tests/run-risks.sh
  - humans/active/HUMAN-ADMIN-admin.md
  - tickets/open/POS-0100-*
  - tickets/closed/POS-0100-*
  - reports/POS-0100-technical-report.md
  - reports/POS-0100-reviewer-note.md
  - reports/human/POS-0100-human-report.md
  - reports/evidence/POS-0100/**
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
  - bats tests/palari_acceptance.bats
  - ./tests/run-human-governance.sh
  - ./tests/run-risks.sh
target_branch: main
branch: ticket/POS-0100
worktree:
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0100 Stable actor identity for acceptance

## Goal

Acceptance and separation-of-duty checks compare stable human/person identity,
not display names, role labels, or interchangeable aliases.

## Scope

- Add or normalize a stable identity field for human profiles.
- Ensure acceptance checks use that stable identity when comparing implementer,
  primary acceptor, and co-acceptors.
- Prevent aliases such as founder/admin from satisfying actor separation when
  they represent the same person.
- Preserve explicitly configured solo-founder behavior where the repo already
  allows one-human flows.
- Update focused acceptance/human-governance tests and docs.

## Acceptance

- Human profiles can declare or derive a stable identity such as `person_id`.
- `HUMAN-FOUNDER` and `HUMAN-ADMIN` style aliases with the same stable identity
  cannot bypass self-acceptance or co-acceptance separation.
- Failure messages name the stable identity conflict clearly enough to fix the
  profile/configuration.
- Existing valid one-human acceptance remains usable where the governance
  configuration intentionally permits it.
- Path and risk rules are respected.

## Verification

- bats tests/palari_acceptance.bats
- ./tests/run-human-governance.sh
- ./tests/run-risks.sh

## Ticket Completion Contract

### Non-Goals

- Do not change policy acceptance behavior.
- Do not change broker behavior or enable real broker side effects.
- Do not change ticket risk scoring, evidence scoring, or adoption behavior.
- Do not change secrets, dependencies, lockfiles, runtime state, deployment,
  push, merge, or acceptance bookkeeping for any existing ticket.

### Definition Of Done

Acceptance gates fail closed when two actor labels map to the same stable
person identity and actor separation is required.

### Evidence Required

- Focused acceptance and human-governance tests.
- POS-0100 CI evidence, evidence score, scope-check, report-lint, technical
  report, human report, and fresh-context reviewer note.

### Expansion Rules

- Stop or split if this grows into configurable quorum redesign, policy
  acceptance, broker enforcement, retrospective governance, or wholesale human
  profile migration unrelated to acceptance identity.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
