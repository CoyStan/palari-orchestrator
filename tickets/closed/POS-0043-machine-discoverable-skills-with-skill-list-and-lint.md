---
id: POS-0043
title: Machine-discoverable skills with skill list and lint
status: accepted
risk: R2
priority: P1
stream: governance
serves_goal: 
claimed_by: claude
claimed_at: 2026-06-11T13:42:06Z
claim_ref: refs/palari/claims/POS-0043
claim_heartbeat_at: 2026-06-11T18:21:12Z
claim_expires_at: 2026-06-11T18:26:12Z
allowed_paths:
  - skills/**
  - plugin/skills/**
  - agent-skills/**
  - lib/palari/adapters_snapshot.bash
  - bin/palari
  - tests/**
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - tickets/open/POS-0043*
  - tickets/closed/POS-0043*
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
  - tests/run-skills.sh
  - ./bin/palari lint
  - shellcheck -x bin/palari lib/palari/adapters_snapshot.bash
target_branch: main
branch: ticket/POS-0043
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T18:21:13Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0043 Machine-discoverable skills with skill list and lint

## Goal

Shipped Palari skills become machine-discoverable. Every shipped skill
(`skills/*/SKILL.md`, `plugin/skills/*/SKILL.md`) carries YAML frontmatter with
`name` and `description`. New commands `palari skill list` and
`palari skill lint` enumerate and validate skills. The linter fails skills that
are missing frontmatter, have duplicate or invalid names, or claim authority
they may never hold (accept, merge, push, or overriding AGENTS.md). Skills
guide behavior; tickets and gates enforce authority.

## Scope

- Add frontmatter to `skills/orchestrator`, `skills/planner`, `skills/adoption`.
- Add `cmd_skill_list` and `cmd_skill_lint` to `lib/palari/adapters_snapshot.bash`.
- Wire `skill list|lint` into `bin/palari` dispatch and usage text.
- Add `tests/run-skills.sh` and wire it into CI workflows.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-skills.sh
- ./bin/palari lint
- shellcheck -x bin/palari lib/palari/adapters_snapshot.bash

## Ticket Completion Contract

### Non-Goals

- Hardened container/VM sandboxing.
- Autonomous execution modes.
- Changes to acceptance authority.

### Definition Of Done

- `palari skill list` prints name, path, and description for all shipped and
  adopter skills.
- `palari skill lint` passes on the repo and fails on a skill claiming
  acceptance/merge authority (covered by tests).
- All shipped skills have valid frontmatter.

### Evidence Required

- Technical report with verification output.
- `palari ci` evidence bundle.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
