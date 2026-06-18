---
id: POS-0101
title: First class worktree integration closeout
status: open
risk: R3
priority: P1
stream: process
serves_goal:
model_hint:
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - lib/palari/tickets_workspace.bash
  - contracts/worktree-first.md
  - README.md
  - tests/run-worktree-closeout.sh
  - tests/run-golden.sh
  - tickets/open/POS-0101-*
  - tickets/closed/POS-0101-*
  - reports/POS-0101-technical-report.md
  - reports/POS-0101-reviewer-note.md
  - reports/human/POS-0101-human-report.md
  - reports/evidence/POS-0101/**
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
  - bash -n lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh
  - ./tests/run-worktree-closeout.sh
  - ./tests/run-golden.sh
target_branch: ticket/POS-0100
branch: ticket/POS-0101
worktree:
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0101 First class worktree integration closeout

## Goal

Add a first-class worktree-to-review closeout preparation workflow so agents do
not manually copy reports, evidence, or branch state between ticket worktrees
and the canonical checkout.

## Scope

- Add a supported command or subcommand that verifies the current checkout is
  the ticket worktree for the requested ticket.
- The workflow must report ticket ID, branch, target branch, worktree path,
  changed path count, evidence status, report status, scope status, and the
  exact next command needed to proceed.
- It may write no product/runtime state and should default to read-only
  verification. If it writes an artifact, it must be a deterministic repo-native
  handoff/closeout artifact under an explicitly allowed path.
- Update README and the worktree-first contract so agents know the supported
  closeout path.
- Add focused regression coverage.

## Acceptance

- Running the closeout workflow from the correct ticket worktree succeeds and
  prints a clear ready/pending state.
- Running it from the canonical checkout or a wrong branch fails with a precise
  message.
- The workflow distinguishes at least these states:
  - wrong checkout/branch,
  - dirty worktree,
  - missing evidence,
  - missing reports,
  - scope failure,
  - ready for review.
- It gives exact next commands for evidence refresh, report completion, ticket
  review transition, and reviewer packet generation.
- Reports and evidence are referenced from the ticket worktree; no manual copy
  instructions are required.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/tickets_workspace.bash tests/run-worktree-closeout.sh
- ./tests/run-worktree-closeout.sh
- ./tests/run-golden.sh

## Ticket Completion Contract

### Non-Goals

- Do not accept tickets.
- Do not merge, push, deploy, or create PRs.
- Do not change acceptance authority, policy acceptance, broker behavior,
  adoption behavior, evidence scoring, runtime state, secrets, dependencies, or
  lockfiles.
- Do not implement the later atomic evidence refresh ticket.
- Do not make worktree closeout destructive.

### Definition Of Done

Agents have one supported local command for ticket worktree closeout
preparation, and that command fails closed when run from the wrong checkout or
when the ticket is not ready for review.

### Evidence Required

- Focused shell regression test.
- POS-0101 technical report, human report, CI evidence, scope-check,
  report-lint, and fresh-context reviewer note.

### Expansion Rules

- Stop or split if the change grows into acceptance, merge automation, push/PR
  automation, GitHub workflow changes, or atomic evidence refresh semantics.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
