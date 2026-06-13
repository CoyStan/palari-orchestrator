---
id: POS-0057
title: Add landed capability state map
status: accepted
risk: R1
priority: P1
stream: docs
serves_goal: 
model_hint: 
claimed_by: codex
claimed_at: 2026-06-12T08:52:12Z
claim_ref: refs/palari/claims/POS-0057
claim_heartbeat_at: 2026-06-12T08:55:33Z
claim_expires_at: 2026-06-12T09:00:33Z
allowed_paths:
  - STATE.md
  - docs/current-capabilities.md
  - docs/**
  - bin/palari
  - lib/palari/*.bash
  - tests/run-cli-structure.sh
  - tests/run-readme-assets.sh
  - tests/run-state.sh
  - tickets/open/POS-0057*
  - tickets/closed/POS-0057*
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
  - test -f STATE.md -o -f docs/current-capabilities.md
  - tests/run-state.sh
  - ./bin/palari lint POS-0057
  - tests/run-cli-structure.sh
  - bash -n bin/palari lib/palari/state.bash tests/run-state.sh
  - git diff --check
target_branch: main
branch: ticket/POS-0057
worktree: 
accepted_by: quetza
accepted_at: 2026-06-12T08:56:46Z
created: 2026-06-12
updated: 2026-06-12
---

# POS-0057 Add landed capability state map

## Goal

Add a repo state / landed capability map so future collaborators and agents can
quickly see what Palari already supports before duplicating work.

## Scope

- Add `STATE.md` or `docs/current-capabilities.md` as the primary orientation
  surface.
- Map capabilities by status:
  - shipped
  - experimental / opt-in
  - planned
  - intentionally not supported
- Cover the main Palari surfaces:
  - ticket governance and human gates
  - worktrees, sandboxes, and isolation language
  - executors (`mock`, `opencode`, `codex`, `openrouter`)
  - OpenRouter/model routing and advisor behavior
  - dashboard/console proof surfaces
  - reports, evidence bundles, executor refusal evidence
  - signed acceptance / ForgeGate
  - plugins, skills, roles, prompts
  - research and DeepSeek pilot artifacts
- If it stays small, add a lightweight CLI surface such as `palari state` or
  `palari doctor capabilities` that prints/points to the state document.
- Add focused tests/docs checks for any new CLI surface.

## Acceptance

- A fresh collaborator can understand what is already landed without reading
  the full changelog or rebuilding existing features.
- The state map clearly distinguishes shipped vs experimental vs planned vs not
  supported.
- OpenRouter/model routing and fast snapshot status are represented accurately
  without implying real API usage or safety/performance claims beyond current
  evidence.
- If a CLI command is added, it is discoverable from `./bin/palari help` and
  covered by structure/smoke tests.
- Path and risk rules are respected.

## Verification

- test -f STATE.md -o -f docs/current-capabilities.md
- tests/run-state.sh
- ./bin/palari lint POS-0057
- tests/run-cli-structure.sh
- bash -n bin/palari lib/palari/state.bash tests/run-state.sh
- git diff --check

## Non-Goals

- Do not add new runtime dependencies.
- Do not change executor behavior, OpenRouter behavior, acceptance authority, or
  merge/push gates.
- Do not make new safety, speed, productivity, or performance claims not already
  backed by accepted evidence.
- Do not start a broader docs rewrite.

## Evidence Required

- Technical report explaining the state map structure and any CLI surface.
- Reviewer note confirming the map is accurate against current repo features.
- Palari CI evidence for POS-0057.
