---
id: POS-0046
title: Related skills in ticket frontmatter and packets
status: accepted
risk: R2
priority: P1
stream: governance
serves_goal: 
claimed_by: claude
claimed_at: 2026-06-11T16:27:09Z
claim_ref: refs/palari/claims/POS-0046
claim_heartbeat_at: 2026-06-11T18:21:16Z
claim_expires_at: 2026-06-11T18:26:16Z
allowed_paths:
  - bin/palari
  - lib/palari/agents_review_scope.bash
  - lib/palari/adapters_snapshot.bash
  - lib/palari/tickets_workspace.bash
  - schemas/**
  - tests/**
  - .github/workflows/**
  - CHANGELOG.md
  - README.md
  - AGENTS.md
  - tickets/open/POS-0046*
  - tickets/closed/POS-0046*
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
  - shellcheck -x bin/palari lib/palari/agents_review_scope.bash
target_branch: main
branch: ticket/POS-0046
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T18:21:18Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0046 Related skills in ticket frontmatter and packets

## Goal

Tickets can name the skills that govern their work, and packets carry those
skills to the executor. Tickets support `related_skills` frontmatter
(`--skill NAME` at creation). `palari packet TICKET-ID ROLE` injects a
Relevant Skills section listing each related skill with its description and a
capped excerpt. `palari lint` warns when a ticket references a skill that does
not exist. Skills remain advisory: packets carry them, tickets scope work,
gates enforce.

## Scope

- `related_skills` parsing in ticket create and lint.
- Packet injection in `lib/palari/agents_review_scope.bash`.
- Skill resolution helper shared with `skill list` from POS-0043.
- Tests in `tests/run-skills.sh`; schema update if ticket schema exists.

## Acceptance

- The scoped result exists.
- Path and risk rules are respected.

## Verification

- tests/run-skills.sh
- ./bin/palari lint
- shellcheck -x bin/palari lib/palari/agents_review_scope.bash

## Ticket Completion Contract

### Non-Goals

- Hardened container/VM sandboxing.
- Autonomous execution modes.
- Changes to acceptance authority.

### Definition Of Done

- A ticket created with `--skill palari-adoption` produces a packet containing
  the skill name, description, and excerpt.
- `palari lint` warns on a missing related skill (covered by tests).

### Evidence Required

- Technical report with verification output.
- `palari ci` evidence bundle.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
