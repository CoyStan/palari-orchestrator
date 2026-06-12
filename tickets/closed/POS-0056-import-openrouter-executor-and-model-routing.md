---
id: POS-0056
title: Import OpenRouter executor and model routing
status: accepted
risk: R2
priority: P1
stream: agent
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-12T04:47:50Z
claim_ref: refs/palari/claims/POS-0056
claim_heartbeat_at: 2026-06-12T08:36:58Z
claim_expires_at: 2026-06-12T08:41:58Z
allowed_paths:
  - .gitattributes
  - AGENTS.md
  - CHANGELOG.md
  - palari.config.yaml
  - adapters/openrouter/**
  - adapters/snapshot/**
  - adapters/web/server.py
  - adapters/web/static/app.js
  - bin/palari
  - lib/palari/adapters_snapshot.bash
  - lib/palari/agents_review_scope.bash
  - lib/palari/core.bash
  - lib/palari/gate.bash
  - lib/palari/hygiene.bash
  - lib/palari/models.bash
  - lib/palari/run.bash
  - lib/palari/tickets_workspace.bash
  - roles/active/.gitkeep
  - schemas/palari.config.schema.json
  - tests/run-cli-structure.sh
  - tests/run-dashboard-rubric.sh
  - tests/run-gate.sh
  - tests/run-model-routing.sh
  - tests/run-openrouter.sh
  - tests/run-performance.sh
  - tests/run-readme-assets.sh
  - tickets/open/POS-0056*
  - tickets/closed/POS-0056*
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
verification:
  - tests/run-model-routing.sh
  - tests/run-openrouter.sh
  - tests/run-performance.sh
  - tests/run-cli-structure.sh
  - tests/run-dashboard-rubric.sh
  - tests/run-gate.sh
  - tests/run-readme-assets.sh
  - python3 -m py_compile adapters/openrouter/run.py adapters/snapshot/fast_snapshot.py adapters/web/server.py
  - bash -n bin/palari lib/palari/*.bash tests/run-model-routing.sh tests/run-openrouter.sh tests/run-performance.sh
target_branch: main
branch: ticket/POS-0056
worktree: 
accepted_by: quetza
accepted_at: 2026-06-12T08:36:59Z
created: 2026-06-12
updated: 2026-06-12
---

# POS-0056 Import OpenRouter executor and model routing

## Goal

Safely import the OpenRouter/model-routing repo snapshot without replacing
accepted Palari history. The result should add optional, opt-in model routing
and OpenRouter text-artifact execution while preserving repo-native gates,
evidence, and human acceptance authority.

## Scope

- Add risk-tiered model routing (`fast`, `balanced`, `frontier`) and
  `palari model routes|show`.
- Add optional OpenRouter executor support with allowlisted models, env-only
  API key lookup, offline test transport, deterministic defaults, and executor
  evidence.
- Add the stdlib Python fast snapshot adapter for read-only dashboard/status
  paths, with Bash fallback.
- Surface executor evidence/refusals in the dashboard review surface.
- Preserve all existing accepted tickets, reports, and evidence.
- Do not add package-manager, database, frontend build, or network-required
  test dependencies.

## Acceptance

- OpenRouter remains disabled by default and refuses runs unless enabled,
  configured, and allowlisted.
- OpenRouter tests run without network access or real credentials.
- `agent run` records resolved model, model source, and model class in
  executor evidence.
- Fast snapshot paths are read-only and have Bash fallback controls.
- Existing governance gates, scope checks, accept authority, and report/evidence
  lifecycle are not weakened.
- Path and risk rules are respected.

## Verification

- tests/run-model-routing.sh
- tests/run-openrouter.sh
- tests/run-performance.sh
- tests/run-cli-structure.sh
- tests/run-dashboard-rubric.sh
- tests/run-gate.sh
- tests/run-readme-assets.sh
- python3 -m py_compile adapters/openrouter/run.py adapters/snapshot/fast_snapshot.py adapters/web/server.py
- bash -n bin/palari lib/palari/*.bash tests/run-model-routing.sh tests/run-openrouter.sh tests/run-performance.sh

## Ticket Completion Contract

### Non-Goals

- Do not run real OpenRouter API calls.
- Do not store API keys, tokens, credentials, request auth headers, or secrets.
- Do not delete accepted Palari reports/evidence that were absent from the zip.
- Do not commit, push, merge, or accept without explicit human approval.

### Definition Of Done

- Imported files are reviewed, adjusted for local `origin/main`, and covered by
  POS-0056 verification.
- POS-0056 has technical and reviewer reports plus CI evidence.

### Evidence Required

- Technical report explaining imported changes, safety choices, and comparison
  against the zip.
- Reviewer note from a fresh review pass.
- Palari CI evidence bundle and the verification commands listed above.

### Expansion Rules

- Stop if the import requires real network calls, credentials, destructive git
  operations, broad report/evidence deletion, or changed acceptance authority.

### Final Review Gate

- Reviewer checks scope, default-disabled OpenRouter posture, no secret storage,
  offline test behavior, dashboard evidence display, and fast snapshot fallback
  before recommending accept, reopen, or needs-human.
