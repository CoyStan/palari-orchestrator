---
id: POS-0049
title: Packet skill polish from review findings
status: open
risk: R1
priority: P2
stream: governance
serves_goal: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - lib/palari/agents_review_scope.bash
  - lib/palari/tickets_workspace.bash
  - tests/**
  - CHANGELOG.md
  - tickets/open/POS-0049*
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
  - tests/run-skills.sh
  - tests/run-agent-mock.sh
target_branch: main
branch: ticket/POS-0049
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0049 Packet skill polish from review findings

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-skills.sh
- tests/run-agent-mock.sh
