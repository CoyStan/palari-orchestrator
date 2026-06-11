---
id: POS-0047
title: Deterministic mock executor for demos and tests
status: in-review
risk: R2
priority: P0
stream: governance
serves_goal: 
claimed_by: claude
claimed_at: 2026-06-11T16:33:24Z
claim_ref: refs/palari/claims/POS-0047
claim_heartbeat_at: 2026-06-11T16:33:24Z
claim_expires_at: 2026-06-11T16:38:24Z
allowed_paths:
  - bin/palari
  - lib/palari/agents_review_scope.bash
  - tests/**
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - tickets/open/POS-0047*
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
requires_human_confirmation: false
requires_review: true
required_reports:
  - technical
verification:
  - tests/run-agent-mock.sh
  - ./bin/palari lint
  - shellcheck -x bin/palari lib/palari/agents_review_scope.bash
target_branch: main
branch: ticket/POS-0047
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0047 Deterministic mock executor for demos and tests

## Goal

Palari's governance is demonstrable without any external AI tool. A
deterministic mock executor runs through the same lifecycle as real executors:
`palari agent run TICKET-ID --executor mock --scenario safe|forbidden-path|outside-scope`.
The safe scenario edits inside allowed paths and passes gates; forbidden-path
touches a forbidden file and is refused by scope-check; outside-scope edits an
unscoped path and is refused. Evidence is written under
`reports/evidence/TICKET-ID/executor/mock/` either way, and failures never
advance ticket state.

## Scope

- Refactor `cmd_agent_run` so executor invocation is a per-executor shim and
  the lifecycle (worktree, packet, evidence, gates) is shared.
- Add the mock executor shim and `--scenario` flag.
- Add `tests/run-agent-mock.sh` and wire it into CI workflows.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-agent-mock.sh
- ./bin/palari lint
- shellcheck -x bin/palari lib/palari/agents_review_scope.bash

## Ticket Completion Contract

### Non-Goals

- Hardened container/VM sandboxing.
- Autonomous execution modes.
- Changes to acceptance authority.

### Definition Of Done

- All three scenarios behave as specified with evidence written (covered by
  tests, no network, no AI CLI required).
- The opencode path still works unchanged (existing tests pass).

### Evidence Required

- Technical report with verification output.
- `palari ci` evidence bundle.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
