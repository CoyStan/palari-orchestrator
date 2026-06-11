---
id: POS-0050
title: Claude plugin packaging scope
status: accepted
risk: R2
priority: P1
stream: governance
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T17:59:21Z
claim_ref: refs/palari/claims/POS-0050
claim_heartbeat_at: 2026-06-11T18:15:05Z
claim_expires_at: 2026-06-11T18:20:05Z
allowed_paths:
  - .claude-plugin/**
  - plugin/**
  - adapters/codex/**
  - tests/run-plugin-structure.sh
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - tickets/open/POS-0050*
  - tickets/closed/POS-0050*
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
  - tests/run-plugin-structure.sh
  - ./bin/palari skill lint
  - shellcheck -x adapters/codex/install.sh tests/run-plugin-structure.sh
target_branch: main
branch: ticket/POS-0050
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T18:15:07Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0050 Claude plugin packaging scope

## Goal

Govern the Claude/plugin packaging files that arrived with the POS-0043 through
POS-0049 stack but were not inside any accepted ticket scope. This ticket makes
the package metadata, command prompts, specialist/reviewer agent prompts,
plugin skill copy, and plugin-structure validation explicit before the stack can
be integrated to `main`.

## Scope

- `.claude-plugin/marketplace.json`.
- `plugin/.claude-plugin/plugin.json`.
- `plugin/README.md`.
- `plugin/agents/**`.
- `plugin/commands/**`.
- `plugin/skills/**`.
- `adapters/codex/**` prompt/install packaging that supports the plugin path.
- `tests/run-plugin-structure.sh` and CI workflow wiring that validates the
  plugin package shape.
- README/CHANGELOG notes required to describe the packaged surfaces.

## Acceptance

- The plugin package has a valid marketplace manifest and plugin manifest.
- The plugin command and agent prompt files exist and are covered by
  `tests/run-plugin-structure.sh`.
- The package does not introduce browser-side or plugin-side authority to
  accept, merge, push, deploy, or bypass Palari gates.
- Path and risk rules are respected.

## Verification

- tests/run-plugin-structure.sh
- ./bin/palari skill lint
- shellcheck -x adapters/codex/install.sh tests/run-plugin-structure.sh

## Ticket Completion Contract

### Non-Goals

- Changing Palari acceptance authority.
- Adding new lifecycle state transitions.
- Adding secrets, production credentials, deploy behavior, or remote services.
- Broadly re-scoping POS-0043 through POS-0049 implementation work.

### Definition Of Done

- POS-0050 covers the previously unscoped plugin packaging paths that blocked
  the POS-0043 through POS-0049 integration gate.
- Plugin structure, skill lint, and shell syntax checks pass.
- The technical report explains the overlap with POS-0043 through POS-0049 and
  the remaining human gate.

### Evidence Required

- `reports/POS-0050-technical-report.md`.
- Palari CI evidence, preferably as part of the POS-0043 through POS-0050
  integration bundle.
- Fresh reviewer note before acceptance.

### Expansion Rules

- Stop if packaging needs acceptance/merge/push authority, external account
  setup, marketplace publication, credentials, or a broader plugin architecture
  redesign.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
