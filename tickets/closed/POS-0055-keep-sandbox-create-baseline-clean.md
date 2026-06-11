---
id: POS-0055
title: Keep sandbox create baseline clean
status: accepted
risk: R1
priority: P0
stream: test
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T23:01:17Z
claim_ref: refs/palari/claims/POS-0055
claim_heartbeat_at: 2026-06-11T23:04:47Z
claim_expires_at: 2026-06-11T23:09:47Z
allowed_paths:
  - lib/palari/tickets_workspace.bash
  - tests/run-sandbox.sh
  - CHANGELOG.md
  - tickets/open/POS-0055*
  - tickets/closed/POS-0055*
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
  - tests/run-sandbox.sh
  - bash -n lib/palari/tickets_workspace.bash tests/run-sandbox.sh
target_branch: main
branch: ticket/POS-0055
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T23:06:43Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0055 Keep sandbox create baseline clean

## Goal

Fix the CI-blocking sandbox baseline regression discovered while merging the
POS-0051..POS-0054 batch. A newly created local sandbox should list and inspect
as clean immediately after `palari sandbox create`.

## Scope

- Keep the change inside sandbox lifecycle code and its direct test/docs notes.
- Ensure files produced by the sandbox repo's own `palari init` are committed
  into the sandbox baseline before the sandbox is handed to an executor.
- Do not change sandbox destroy safety checks or claim/worktree semantics.

## Acceptance

- `tests/run-sandbox.sh` passes locally.
- A new sandbox lists as `0 changed path(s)` immediately after creation.
- Existing non-sandbox destroy refusal remains covered.
- Path and risk rules are respected.

## Verification

- tests/run-sandbox.sh
- bash -n lib/palari/tickets_workspace.bash tests/run-sandbox.sh
