---
id: POS-0044
title: Honest sandbox terminology and isolation docs
status: accepted
risk: R1
priority: P2
stream: docs
serves_goal: 
claimed_by: claude
claimed_at: 2026-06-11T14:43:44Z
claim_ref: refs/palari/claims/POS-0044
claim_heartbeat_at: 2026-06-11T18:21:13Z
claim_expires_at: 2026-06-11T18:26:13Z
allowed_paths:
  - README.md
  - docs/**
  - adapters/opencode/README.md
  - adapters/codex/README.md
  - contracts/**
  - CHANGELOG.md
  - tickets/open/POS-0044*
  - tickets/closed/POS-0044*
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
requires_review: false
required_reports:
  - technical
verification:
  - git diff --check
  - ./bin/palari lint
target_branch: main
branch: ticket/POS-0044
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T18:21:15Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0044 Honest sandbox terminology and isolation docs

## Goal

Palari documentation states isolation guarantees honestly. Docs distinguish
three terms used consistently: worktree (normal ticket implementation
isolation), local sandbox (disposable repo copy protecting the canonical
checkout from accidental dirtying), and hardened sandbox (future
container/VM/remote isolation, not yet shipped). Docs explicitly say the local
sandbox is not a security boundary and that scope/evidence gates are the real
control layer.

## Scope

- README isolation section.
- `docs/` and `contracts/` wording where sandbox guarantees are implied.
- Codex/opencode adapter READMEs.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- git diff --check
- ./bin/palari lint
