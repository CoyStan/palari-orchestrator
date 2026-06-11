---
id: POS-0052
title: Fix README asset archive packaging
status: open
risk: R1
priority: P1
stream: docs
serves_goal: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - .gitattributes
  - README.md
  - assets/readme/**
  - tests/run-readme-assets.sh
  - .github/workflows/**
  - CHANGELOG.md
  - tickets/open/POS-0052*
  - tickets/closed/POS-0052*
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
  - tests/run-readme-assets.sh
  - git archive --format=tar HEAD | tar -tf - | grep -Fq assets/readme/palari-orchestrator-hero-general.png
target_branch: main
branch: ticket/POS-0052
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0052 Fix README asset archive packaging

## Goal

State the result this ticket should produce.

## Scope

List what may change.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-readme-assets.sh
- git archive --format=tar HEAD | tar -tf - | grep -Fq assets/readme/palari-orchestrator-hero-general.png
