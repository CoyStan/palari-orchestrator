---
id: POS-0051
title: Fix external Palari root invocation
status: in-review
risk: R2
priority: P0
stream: governance
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T21:34:17Z
claim_ref: refs/palari/claims/POS-0051
claim_heartbeat_at: 2026-06-11T21:37:56Z
claim_expires_at: 2026-06-11T21:42:56Z
allowed_paths:
  - bin/palari
  - scripts/palari
  - tests/run-adoption.sh
  - tests/run-cli-structure.sh
  - adapters/codex/README.md
  - CHANGELOG.md
  - tickets/open/POS-0051*
  - tickets/closed/POS-0051*
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
  - tests/run-adoption.sh
  - tests/run-cli-structure.sh
  - shellcheck -x bin/palari scripts/palari tests/run-adoption.sh tests/run-cli-structure.sh
target_branch: main
branch: ticket/POS-0051
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0051 Fix external Palari root invocation

## Goal

Make Palari package invocation reliable when `bin/palari` or `scripts/palari`
is called from outside the Palari package root. The motivating case is Codex or
a human running `/path/to/palari/bin/palari adopt /path/to/target --dry-run`
from the target repository or another directory.

## Scope

- Root detection in `bin/palari`.
- Wrapper root pinning in `scripts/palari`.
- Adoption regression coverage for external package invocation.
- Codex adapter docs and changelog wording for the safer install contract.

## Acceptance

- External package invocation works from a target git repo.
- External package invocation works from a non-repo temporary directory.
- `scripts/palari` pins `PALARI_ROOT` to the package root.
- Path and risk rules are respected.

## Verification

- tests/run-adoption.sh
- tests/run-cli-structure.sh
- shellcheck -x bin/palari scripts/palari tests/run-adoption.sh tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Changing adoption copy semantics.
- Changing ticket lifecycle, acceptance, merge, or executor authority.
- Adding network, marketplace, or installer side effects.

### Definition Of Done

- `tests/run-adoption.sh` reproduces and protects the external invocation
  case.
- Existing adoption and CLI structure checks pass.
- Codex docs no longer depend on brittle "current CLI version" wording.

### Evidence Required

- `reports/POS-0051-technical-report.md`.
- Palari CI evidence bundle.
- Fresh reviewer note recommending accept, reopen, or needs-human.

### Expansion Rules

- Stop if the fix requires changing package layout, install behavior,
  acceptance authority, or shelling out to external services.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
