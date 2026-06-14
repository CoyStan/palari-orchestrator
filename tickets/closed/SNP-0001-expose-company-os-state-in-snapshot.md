---
id: SNP-0001
title: Expose company OS state in snapshot
status: accepted
risk: R3
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T23:12:22Z
claim_ref: refs/palari/claims/SNP-0001
claim_heartbeat_at: 2026-06-14T23:25:25Z
claim_expires_at: 2026-06-14T23:30:25Z
allowed_paths:
  - lib/palari/**
  - adapters/snapshot/**
  - adapters/planning/**
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/SNP-0001*
  - tickets/closed/SNP-0001*
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
  - ./tests/run-company-os-snapshot.sh
  - ./tests/run-performance.sh
  - ./tests/run-dashboard-rubric.sh
target_branch: main
branch: ticket/SNP-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-14T23:25:44Z
created: 2026-06-14
updated: 2026-06-14
---

# SNP-0001 Expose company OS state in snapshot

## Goal

Expose compact Company OS governance state in `palari snapshot --json` and
`palari web --check` without slowing the fast snapshot path or mutating state.

## Scope

- Add a shared read-only company OS snapshot builder.
- Add a top-level `company_os` section to fast snapshot output.
- Add the same `company_os` section to the Bash snapshot fallback.
- Include workflow counts, active workflow HGL summaries, human profile counts,
  open R3/R4/R5 decision counts, missing skills, bottlenecks, autonomy gate
  distribution, policy simulation posture, and broker side-effect posture.
- Add focused snapshot regression coverage and update existing dashboard
  snapshot-contract checks.

## Acceptance

- `./bin/palari snapshot --json` includes `company_os`.
- `PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json` includes
  `company_os`.
- `./bin/palari web --check` includes `company_os`.
- Absent workflow/human directories or empty state produce empty counts, not
  crashes.
- Fast snapshot performance remains within the existing budget.
- No lifecycle state, policy state, broker state, credentials, network calls,
  external writes, or dashboard mutation behavior changes.
- Path and risk rules are respected.

## Verification

- ./tests/run-company-os-snapshot.sh
- ./tests/run-performance.sh
- ./tests/run-dashboard-rubric.sh

## Ticket Completion Contract

### Non-Goals

- Do not add dashboard cards or UI rendering for Company OS state.
- Do not add policy artifacts, policy simulation, broker evidence, outcome
  records, secure posture checks, or external side effects.
- Do not make HGL scoring more sophisticated than the accepted HGL contract.

### Definition Of Done

- Fast and Bash snapshots expose the same top-level `company_os` contract.
- The section is deterministic and safe when no Company OS artifacts exist.
- Tests cover populated workflow/human fixtures and empty live repo behavior.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report for the R3 human gate.
- Focused snapshot test output.
- Performance and dashboard snapshot-contract checks.
- CI evidence bundle for SNP-0001.

### Expansion Rules

- Stop if this requires UI/dashboard work, policy behavior, broker behavior,
  lifecycle mutation, external calls, credentials, or non-stdlib dependencies.

### Final Review Gate

- Reviewer confirms the snapshot addition is additive, read-only, fast enough,
  and consistent across fast/Bash/web surfaces before recommending accept,
  reopen, or needs-human.
