---
id: POS-0037
title: Prompt generator for long-run agent work
status: accepted
risk: R2
priority: P1
stream: cli
claimed_by: codex
claimed_at: 2026-06-10T21:41:55Z
claim_ref: refs/palari/claims/POS-0037
claim_heartbeat_at: 2026-06-11T05:13:50Z
claim_expires_at: 2026-06-11T05:18:50Z
allowed_paths:
  - bin/palari
  - lib/palari/prompt.bash
  - lib/palari/init_adopt.bash
  - tests/run-prompt.sh
  - tests/run-cli-structure.sh
  - tests/run-golden.sh
  - tickets/open/POS-0037-*.md
  - tickets/closed/POS-0037-*.md
  - reports/POS-0037-technical-report.md
  - reports/POS-0037-reviewer-note.md
  - reports/evidence/POS-0037/**
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
  - tests/run-prompt.sh
  - tests/run-cli-structure.sh
  - bash -n bin/palari lib/palari/*.bash
  - git diff --check
target_branch: main
branch: ticket/POS-0037
worktree: /home/quetza/palari-orchestrator-worktrees/POS-0037
accepted_by: quetza
accepted_at: 2026-06-11T05:13:52Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0037 Prompt generator for long-run agent work

## Goal

Add a repo-native prompt generator that helps founders and operators hand off
Palari work to a fresh agent without rewriting lifecycle, role, evidence, and
stopping-rule instructions by hand.

## Scope

- Add `palari prompt` commands for:
  - the next active ticket/action,
  - a specific ticket,
  - long-running autonomous work from a founder goal.
- Keep the feature read-only: it may inspect ticket/repo state and print
  prompts, but it must not claim, accept, merge, push, or mutate lifecycle
  state.
- Include role guidance, safety constraints, checks, evidence expectations, and
  stop conditions in generated prompts.
- Add focused shell tests for the prompt generator and CLI structure wiring.

## Acceptance

- `./bin/palari prompt next` prints a usable next-action prompt for the first
  active ticket.
- `./bin/palari prompt ticket POS-0037` prints a specific ticket prompt with
  status, scope, verification, and path constraints.
- `./bin/palari prompt long-run --goal "..."` prints a long-running agent prompt
  with roles, execution loop, checks, evidence, and stopping rules.
- The command is documented in CLI usage and covered by tests.
- The implementation stays Bash/stdlib and read-only.

## Verification

- tests/run-prompt.sh
- tests/run-cli-structure.sh
- bash -n bin/palari lib/palari/*.bash
- git diff --check

## Ticket Completion Contract

### Non-Goals

- Do not implement a process supervisor that actually spawns agents.
- Do not add browser-side actions or dashboard changes.
- Do not bypass review, acceptance, merge, push, or ForgeGate authority.
- Do not create broad product-management automation beyond prompt generation.

### Definition Of Done

- A fresh user can run `palari prompt long-run --goal "..."` and receive a
  high-quality prompt that tells an agent how to keep working across safe
  tickets until a true human gate blocks progress.

### Evidence Required

- POS-0037 technical report.
- Palari CI evidence under `reports/evidence/POS-0037/`.
- Test output from `tests/run-prompt.sh` and CLI structure checks.

### Expansion Rules

- Stop if implementation requires agent execution, credentials, dashboard
  mutation, or changes to acceptance/merge authority.

### Final Review Gate

- Reviewer checks generated prompts for clarity, safety, useful role guidance,
  and no unauthorized lifecycle mutation.
