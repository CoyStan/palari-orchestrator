---
id: POS-0045
title: Sandbox lifecycle commands and metadata
status: open
risk: R2
priority: P1
stream: governance
serves_goal: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - lib/palari/tickets_workspace.bash
  - tests/**
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - tickets/open/POS-0045*
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
  - tests/run-sandbox.sh
  - ./bin/palari lint
  - shellcheck -x bin/palari lib/palari/tickets_workspace.bash
target_branch: main
branch: ticket/POS-0045
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0045 Sandbox lifecycle commands and metadata

## Goal

The local sandbox becomes a first-class primitive with a lifecycle. New
commands: `palari sandbox list`, `palari sandbox inspect TICKET-ID`, and
`palari sandbox destroy TICKET-ID`. Sandbox creation writes machine-readable
metadata to `.palari/sandbox.json` (ticket, mode, source repo and commit,
target branch, created_at). `destroy` refuses paths that do not carry the
`.palari-sandbox` marker. `inspect` reports mode, source commit, dirty state,
and changed paths.

## Scope

- Extend `lib/palari/tickets_workspace.bash` sandbox functions.
- Wire new subcommands into `bin/palari` dispatch and usage text.
- Add `tests/run-sandbox.sh` and wire it into CI workflows.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-sandbox.sh
- ./bin/palari lint
- shellcheck -x bin/palari lib/palari/tickets_workspace.bash

## Ticket Completion Contract

### Non-Goals

- Hardened container/VM sandboxing.
- Autonomous execution modes.
- Changes to acceptance authority.

### Definition Of Done

- `sandbox list` shows sandboxes under the worktree base.
- `sandbox inspect` reads `.palari/sandbox.json` and live git state.
- `sandbox destroy` removes a Palari sandbox and refuses anything else
  (covered by tests).

### Evidence Required

- Technical report with verification output.
- `palari ci` evidence bundle.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
