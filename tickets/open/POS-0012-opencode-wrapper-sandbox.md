---
id: POS-0012
title: opencode wrapper sandbox
status: open
risk: R2
priority: P1
stream: adapters
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - README.md
  - contracts/**
  - adapters/opencode/**
  - tests/**
  - reports/**
  - .github/workflows/**
  - tickets/**
forbidden_paths:
  - .env
  - .env.*
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-agent-wrapper.sh
  - tests/run-golden.sh
  - shellcheck bin/palari scripts/palari tests/run-agent-wrapper.sh
  - shfmt -d bin/palari scripts/palari tests/run-agent-wrapper.sh
target_branch: main
branch: ticket/POS-0012
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0012
accepted_by:
accepted_at:
created: 2026-06-07
updated: 2026-06-07
---

# POS-0012 opencode wrapper sandbox

## Goal

Add a small first-class wrapper path for external coding agents, starting with
opencode, while keeping Palari responsible for tickets, packets, evidence,
scope checks, and acceptance authority.

## Scope

- Add a local sandbox creation primitive.
- Add an opencode executor wrapper that runs from a Palari packet and records
  executor evidence.
- Deny executor lifecycle authority such as `palari accept`, `palari ticket
  ready`, and `git push`.
- Add focused tests and adapter documentation.

## Acceptance

- `palari sandbox create TICKET-ID` creates a disposable local repo copy outside
  the canonical checkout and keeps the canonical repo clean.
- `palari agent run TICKET-ID --executor opencode` prepares the ticket
  worktree, generates a packet, runs or dry-runs opencode, exports the session
  when available, and runs Palari gates without accepting work.
- Tests prove the sandbox primitive and dry-run wrapper path without requiring
  opencode credentials in CI.

## Verification

- tests/run-agent-wrapper.sh
- tests/run-golden.sh
- shellcheck bin/palari scripts/palari tests/run-agent-wrapper.sh
- shfmt -d bin/palari scripts/palari tests/run-agent-wrapper.sh

## Ticket Completion Contract

### Non-Goals

- Do not add Codex, Cline, Aider, or other executor adapters yet.
- Do not add a hosted service, dashboard expansion, Docker dependency, or remote
  VM runner.
- Do not let opencode accept work, push, or own Palari lifecycle transitions.

### Definition Of Done

- Palari can wrap opencode as an external executor through a minimal, portable
  CLI surface and preserve Palari authority over gates.

### Evidence Required

- Focused wrapper test output.
- Existing golden flow output.

### Expansion Rules

- Stop if a safer sandbox requires container or remote-infrastructure choices.
- Stop if opencode behavior would require product-specific assumptions.

### Final Review Gate

- Reviewer checks that the new commands are minimal, optional, and preserve the
  core Palari boundary: external agents execute; Palari governs.
