---
id: POS-0053
title: Make default snapshot fast
status: accepted
risk: R2
priority: P0
stream: dashboard
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T21:41:41Z
claim_ref: refs/palari/claims/POS-0053
claim_heartbeat_at: 2026-06-11T22:46:29Z
claim_expires_at: 2026-06-11T22:51:29Z
allowed_paths:
  - bin/palari
  - lib/palari/dashboard_snapshot.bash
  - lib/palari/adapters_snapshot.bash
  - adapters/web/server.py
  - adapters/web/README.md
  - tests/run-dashboard-rubric.sh
  - tests/run-cli-structure.sh
  - .github/workflows/**
  - CHANGELOG.md
  - tickets/open/POS-0053*
  - tickets/closed/POS-0053*
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
requires_human_confirmation: false
requires_review: true
required_reports:
  - technical
verification:
  - tests/run-dashboard-rubric.sh
  - tests/run-cli-structure.sh
  - python3 -m py_compile adapters/web/server.py
target_branch: main
branch: ticket/POS-0053
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T22:47:48Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0053 Make default snapshot fast

## Goal

Make the default dashboard snapshot suitable for frequent console refreshes.
`palari snapshot --json` and `palari web --check` should return a fast active
operator view, while a deliberate `--full` mode preserves slower audit-grade
details.

## Scope

- Add `snapshot --json --full` and `web --check --full`.
- Keep default snapshots focused on active tickets, lightweight role rows,
  evidence/report presence, and shallow role diagnostics.
- Keep full snapshots able to include accepted tickets, full report checks, and
  full role lint.
- Update dashboard adapter docs and contract tests.

## Acceptance

- Default `palari snapshot --json` emits `snapshot_mode: fast`.
- Default `palari web --check` emits the same fast contract.
- Full `palari snapshot --json --full` emits `snapshot_mode: full` and includes
  accepted ticket history plus full role lint diagnostics.
- Dashboard tests cover both modes.
- Path and risk rules are respected.

## Verification

- tests/run-dashboard-rubric.sh
- tests/run-cli-structure.sh
- python3 -m py_compile adapters/web/server.py

## Ticket Completion Contract

### Non-Goals

- Do not redesign the dashboard UI.
- Do not weaken `palari lint`, `palari ci`, `palari accept`, role lint, report
  lint, scope checks, or evidence validation.
- Do not hide expensive diagnostics permanently; keep them available behind a
  deliberate full mode.

### Definition Of Done

- Default dashboard JSON loads the active operator view substantially faster
  than the prior one-minute snapshot path on this repository.
- Full mode remains available for audit and review use cases.
- Relevant shell, dashboard, and Palari checks pass.

### Evidence Required

- Technical report with before/after timing and contract summary.
- Dashboard rubric output.
- Palari lint/CI evidence bundle.
- Fresh reviewer note.

### Expansion Rules

- Stop if changes require a database, frontend build step, persistent cache, or
  browser-side mutation endpoint.
- Stop if a speed change would reduce authority, evidence, review, or acceptance
  gates.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
