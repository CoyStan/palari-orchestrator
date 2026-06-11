---
id: POS-0048
title: Codex executor adapter and codex doctor
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
  - adapters/codex/**
  - bin/palari
  - lib/palari/agents_review_scope.bash
  - tests/**
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - tickets/open/POS-0048*
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
  - tests/run-agent-codex.sh
  - ./bin/palari lint
  - shellcheck -x bin/palari lib/palari/agents_review_scope.bash adapters/codex/install.sh
target_branch: main
branch: ticket/POS-0048
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0048 Codex executor adapter and codex doctor

## Goal

Codex becomes a first-class governed executor. `palari agent run TICKET-ID
--executor codex` follows the shared lifecycle (worktree, packet, evidence,
scope-check, ci) with the Codex CLI contract isolated in a single
`executor_codex_run` shim function. `--dry-run` prints the plan and writes
`command.txt` without invoking Codex. A new `palari codex doctor` (extending
the codex adapter) reports readiness: AGENTS.md present, prompts installed,
executor support available.

## Scope

- Codex executor shim in `lib/palari/agents_review_scope.bash`.
- `adapters/codex/` doctor script and README update.
- Add `tests/run-agent-codex.sh` (dry-run based, no Codex CLI dependency) and
  wire it into CI workflows.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-agent-codex.sh
- ./bin/palari lint
- shellcheck -x bin/palari lib/palari/agents_review_scope.bash adapters/codex/install.sh

## Ticket Completion Contract

### Non-Goals

- Hardened container/VM sandboxing.
- Autonomous execution modes.
- Changes to acceptance authority.

### Definition Of Done

- `agent run --executor codex --dry-run` works without the Codex CLI and
  writes the command plan to evidence.
- A real run shells out through the single shim function only.
- `codex doctor` reports each readiness check (covered by tests).

### Evidence Required

- Technical report with verification output.
- `palari ci` evidence bundle.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
