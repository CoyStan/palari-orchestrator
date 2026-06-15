---
id: WFU-0001
title: Add workflow artifacts and CLI
status: accepted
risk: R3
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T22:28:12Z
claim_ref: refs/palari/claims/WFU-0001
claim_heartbeat_at: 2026-06-14T22:38:25Z
claim_expires_at: 2026-06-14T22:43:25Z
allowed_paths:
  - contracts/**
  - templates/**
  - workflows/**
  - lib/palari/**
  - bin/palari
  - palari.config.yaml
  - schemas/**
  - tests/**
  - README.md
  - STATE.md
  - CHANGELOG.md
  - tickets/open/WFU-0001*
  - tickets/closed/WFU-0001*
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
  - ./tests/run-workflows.sh
  - ./tests/run-cli-structure.sh
target_branch: main
branch: ticket/WFU-0001
worktree:
accepted_by: quetza
accepted_at: 2026-06-14T22:38:45Z
created: 2026-06-14
updated: 2026-06-14
---

# WFU-0001 Add workflow artifacts and CLI

## Goal

Introduce workflow artifacts and a conservative workflow CLI so Palari can
model company/process work above tickets without changing execution or
acceptance behavior.

## Scope

- Workflow directories and config.
- Workflow contract and template.
- Workflow CLI module and bin dispatch.
- Workflow init/doctor support.
- Workflow tests and docs/state/changelog.

## Acceptance

- `palari workflow create` writes a proposed workflow linked to a goal.
- `workflow list`, `show`, and `lint` work.
- `workflow adopt` moves proposed workflows to active with human bookkeeping.
- `workflow close` moves active workflows to closed with an outcome.
- Workflow lint validates ids, status, linked goals, risk ceilings, work units,
  expected decisions, and R3/R4/R5 skill requirements.
- No execution, ticket acceptance, policy acceptance, broker side effects, or
  external writes are introduced.

## Verification

- ./tests/run-workflows.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement HGL scoring.
- Do not implement workflow planning/autonomy ceilings.
- Do not connect workflows to ticket execution.
- Do not add policy, broker, human governance ledger, or outcome behavior.

### Definition Of Done

- Workflow artifact directories exist.
- Workflow module is sourced by the CLI.
- Workflow lifecycle commands are documented and tested.
- Existing CLI structure checks remain green.

### Evidence Required

- Technical report.
- Reviewer note.
- Human/founder report because this is R3 work.
- Palari CI evidence.

### Expansion Rules

- Stop if the workflow CLI would execute agents, accept tickets, mutate policy,
  perform broker actions, or bypass human adoption/closure.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
