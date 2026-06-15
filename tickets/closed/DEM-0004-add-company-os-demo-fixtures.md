---
id: DEM-0004
title: Add company OS demo fixtures
status: accepted
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T00:34:03Z
claim_ref: refs/palari/claims/DEM-0004
claim_heartbeat_at: 2026-06-15T00:45:13Z
claim_expires_at: 2026-06-15T00:50:13Z
allowed_paths:
  - lib/palari/demo.bash
  - workflows/**
  - humans/**
  - policies/**
  - outcomes/**
  - reports/**
  - tests/**
  - README.md
  - assets/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/DEM-0004*
  - tickets/closed/DEM-0004*
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
  - ./tests/run-demo.sh
  - ./tests/run-company-os-demo.sh
  - ./bin/palari demo --company-os --force >/tmp/palari-company-demo.out
target_branch: main
branch: ticket/DEM-0004
worktree: 
accepted_by: quetza
accepted_at: 2026-06-15T00:45:25Z
created: 2026-06-15
updated: 2026-06-15
---

# DEM-0004 Add company OS demo fixtures

## Goal

Add a deterministic local Company OS demo mode that shows the workflow,
human-governance, policy-candidate, broker-evidence, outcome, snapshot, and
web-check shape without external agents or services.

## Scope

- Add `palari demo --company-os`.
- Add a focused Company OS demo regression test.
- Preserve the existing default demo and `--agent-refusal` behavior.
- Update state/changelog/reporting for the new demo mode.

## Acceptance

- `palari demo --company-os --force` creates deterministic local fixtures.
- The demo includes an active goal, active workflow, two active humans, a
  missing `privacy:L5` skill warning, a real policy-candidate signal from
  decided demo decisions, deterministic mock broker evidence, and a recorded
  outcome.
- The demo does not run agents, access network, mutate production, accept
  tickets, push, merge, or deploy.
- `palari workflow plan WF-9004`, `palari snapshot --json`, and
  `palari web --check` work against the fixture.

## Verification

- ./tests/run-demo.sh
- ./tests/run-company-os-demo.sh
- ./bin/palari demo --company-os --force >/tmp/palari-company-demo.out

## Ticket Completion Contract

### Non-Goals

- Dashboard redesign.
- Real agents, hosted services, network calls, credentials, push, merge,
  deploy, or production mutation.
- Changing policy-candidate heuristics.
- Changing broker side-effect authority.

### Definition Of Done

- `palari demo --company-os` creates the Company OS fixture once and requires
  `--force` to replace it.
- `palari demo --company-os --force` is deterministic and repeatable.
- Existing `palari demo` and `palari demo --agent-refusal` tests still pass.

### Evidence Required

- Technical report with changed paths, verification, CI evidence, and residual
  risk notes.
- Reviewer note recommending accept/reopen/needs-human.
- CI evidence bundle under `reports/evidence/DEM-0004/`.

### Expansion Rules

- Stop if the demo needs external agents, network, credentials, or real broker
  side effects.
- Stop if this requires policy acceptance authority instead of simulation-only
  candidate output.

### Final Review Gate

- Reviewer checks deterministic fixtures, no external side effects, unchanged
  existing demos, and green evidence.
