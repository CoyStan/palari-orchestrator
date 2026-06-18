---
id: POS-0107
title: Stable Worktree Base Resolution
status: claimed
risk: R3
priority: P1
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-18T14:01:36Z
claim_ref: refs/palari/claims/POS-0107
claim_heartbeat_at: 2026-06-18T14:01:36Z
claim_expires_at: 2026-06-18T14:06:36Z
allowed_paths:
  - lib/palari/core.bash
  - lib/palari/tickets_workspace.bash
  - tests/run-worktree-closeout.sh
  - tests/run-golden.sh
  - tests/run-cli-structure.sh
  - contracts/worktree-first.md
  - tickets/open/POS-0107-*
  - tickets/closed/POS-0107-*
  - reports/POS-0107-technical-report.md
  - reports/POS-0107-reviewer-note.md
  - reports/human/POS-0107-human-report.md
  - reports/evidence/POS-0107/**
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
  - bash -n lib/palari/core.bash lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh tests/run-golden.sh tests/run-cli-structure.sh
  - ./tests/run-worktree-closeout.sh
  - ./tests/run-golden.sh
  - ./tests/run-cli-structure.sh
target_branch: main
branch: ticket/POS-0107
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0107 Stable Worktree Base Resolution

## Goal

Make configured ticket worktree paths stable from any registered worktree.
Relative `worktree_base` values must resolve from the canonical/common
repository root, not from the currently active ticket worktree.

## Scope

- Worktree base path resolution.
- Ticket worktree path reporting used by `palari worktree`, closeout,
  packets, status, and snapshots.
- Focused regression coverage for stacked worktree creation from inside a
  ticket worktree.
- Worktree documentation if needed.

## Acceptance

- Relative `worktree_base` resolves to one stable flat base from canonical repo
  state, regardless of the current registered worktree.
- Absolute `worktree_base` behavior is preserved.
- Default `worktree_base` behavior is preserved when the config key is absent.
- `palari worktree`, `ticket_declared_worktree`, packet generation, closeout,
  status/snapshot, and related worktree path outputs agree on the same flat
  path.
- Regression coverage proves creating a stacked ticket worktree from inside
  another ticket worktree does not create nested
  `palari-orchestrator-worktrees/palari-orchestrator-worktrees/...` paths.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/core.bash lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh tests/run-golden.sh tests/run-cli-structure.sh
- ./tests/run-worktree-closeout.sh
- ./tests/run-golden.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not change ticket acceptance, evidence freshness semantics, GitHub
  workflow behavior, deployment, secrets, dependencies, lockfiles, or
  unrelated process surfaces.
- Do not clean remote branches or deploy.
- Do not continue the minimax plan beyond this fix.

### Definition Of Done

- Worktree path resolution is canonical and stable.
- Stacked worktree regression coverage fails on the old recursive behavior and
  passes with the fix.
- Existing worktree closeout, golden, and CLI structure tests still pass.

### Evidence Required

- Focused worktree/path regression evidence.
- `./tests/run-worktree-closeout.sh`
- `./tests/run-golden.sh`
- `./tests/run-cli-structure.sh`
- POS-0107 CI evidence.
- Technical report, human report, and fresh-context reviewer note.

### Expansion Rules

- Stop if this requires changing acceptance authority, evidence semantics,
  GitHub workflow behavior, deploy/runtime state, dependencies, lockfiles, or
  branch history.

### Final Review Gate

- Reviewer verifies the canonical worktree base rule, stacked worktree
  regression coverage, and absence of unrelated acceptance/evidence/deploy
  changes, then recommends accept, reopen, or needs-human.
