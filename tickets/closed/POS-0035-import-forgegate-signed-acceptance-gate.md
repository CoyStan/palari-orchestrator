---
id: POS-0035
title: Import ForgeGate signed acceptance gate
status: accepted
risk: R2
priority: P1
stream: governance
claimed_by: codex
claimed_at: 2026-06-10T14:38:29Z
claim_ref: refs/palari/claims/POS-0035
claim_heartbeat_at: 2026-06-11T06:42:43Z
claim_expires_at: 2026-06-11T06:47:43Z
allowed_paths:
  - .github/**
  - .gitignore
  - AGENTS.md
  - CHANGELOG.md
  - README.md
  - adapters/**
  - assets/readme/**
  - bin/**
  - contracts/**
  - docs/**
  - gate/**
  - layouts/**
  - lib/**
  - palari.config.yaml
  - schemas/**
  - tests/**
  - tickets/**
  - reports/**
forbidden_paths:
  - .palari/**
  - .env
  - .env.*
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*.key"
  - "**/*.token.json"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - bash -n bin/palari lib/palari/*.bash tests/run-gate.sh tests/run-gate-kernel.sh
  - tests/run-gate-kernel.sh
  - tests/run-gate.sh
  - tests/run-dashboard-rubric.sh
  - ./bin/palari lint POS-0035
  - git diff --check
target_branch: main
branch: codex/forgegate-side-version
worktree:
accepted_by: founder
accepted_at: 2026-06-11T06:42:52Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0035 Import ForgeGate signed acceptance gate

## Goal

Import the ForgeGate side version as an optional signed acceptance gate for
Palari, while keeping the default repository behavior backward compatible.

## Scope

This ticket may change the Palari CLI, dashboard snapshot/console surfaces,
config/schema/docs, GitHub workflow coverage, and tests needed for the
ForgeGate import.

It must not enable the gate by default, commit private key material, weaken
existing lint/scope/CI gates, or mutate unrelated pilot research tickets.

## Acceptance

- `palari gate` commands are available and backed by the vendored kernel.
- `palari accept` still behaves as before when `gate.enabled: false`.
- When `gate.enabled: true`, acceptance fails closed unless the signed
  implement/test/review chain verifies.
- The dashboard and snapshot expose gate status without adding a write-capable
  browser acceptance action.
- The README, contracts, and integration docs describe the boundary without
  claiming a formal cryptographic audit.
- Local checks pass against `origin/main`; GitHub checks pass against `main`.

## Verification

- bash -n bin/palari lib/palari/*.bash tests/run-gate.sh tests/run-gate-kernel.sh
- tests/run-gate-kernel.sh
- tests/run-gate.sh
- tests/run-dashboard-rubric.sh
- ./bin/palari lint POS-0035
- git diff --check

## Ticket Completion Contract

### Non-Goals

- Running the DeepSeek pilot synthesis or editing POS-0032/POS-0033.
- Enabling ForgeGate by default for every repository.
- Replacing GitHub rulesets, Palari evidence manifests, or human acceptance.
- Treating the reference kernel as a production cryptographic audit.

### Definition Of Done

- The imported side version is represented by a governed PR.
- The optional signed gate can initialize, set up a ticket, attest implement,
  test, and review steps, refuse forgery/tamper/self-review, and allow
  acceptance only on a verified chain.
- Dashboard snapshot/rubric tests cover the new custody surface.

### Evidence Required

- Technical report summarizing the import and checks.
- Reviewer note calling out security boundaries and any limitations.
- Local check output and GitHub check results on the PR.

### Expansion Rules

- Stop if the change needs to store private keys in git, add a database,
  enable browser-side acceptance, or bypass the Palari merge gate.
- Stop if remote CI finds a behavior failure that requires changing the
  acceptance model rather than a ticket/scoping correction.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
