---
id: POS-0103
title: Retrospective governance lifecycle
status: open
risk: R3
priority: P2
stream: process
serves_goal: 
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - bin/palari
  - lib/palari/tickets_workspace.bash
  - lib/palari/agents_review_scope.bash
  - lib/palari/adapters_snapshot.bash
  - contracts/retrospective-governance.md
  - README.md
  - tests/run-retrospective-governance.sh
  - tickets/open/POS-0103-*
  - tickets/closed/POS-0103-*
  - reports/POS-0103-technical-report.md
  - reports/POS-0103-reviewer-note.md
  - reports/human/POS-0103-human-report.md
  - reports/evidence/POS-0103/**
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
requires_human_confirmation: true
requires_review: true
verification:
  - bash -n lib/palari/tickets_workspace.bash lib/palari/agents_review_scope.bash tests/run-retrospective-governance.sh
  - ./tests/run-retrospective-governance.sh
target_branch: ticket/POS-0102
branch: ticket/POS-0103
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0103 Retrospective governance lifecycle

## Goal

Create an explicit retrospective/audit-backfill lifecycle distinct from normal
pre-governed ticket work, so already-landed work cannot be made to look like it
was governed before implementation.

## Scope

- Add ticket frontmatter and lint/report semantics for retrospective claims.
- Retrospective tickets must be visibly marked as retrospective.
- Retrospective tickets must record original commit SHAs and why normal
  governance was bypassed.
- High-risk retrospective claims must require explicit founder/human and
  reviewer evidence.
- Status/snapshot or report output should distinguish normal accepted tickets
  from audit-backfilled tickets.
- Retrospective tickets must not silently set `requires_review: false` for
  high-risk already-landed claims.
- Add focused documentation and regression coverage.

## Acceptance

- A retrospective ticket can be linted and reported as retrospective instead of
  normal pre-governed work.
- Retrospective tickets without original commit SHA evidence fail lint.
- High-risk retrospective tickets without required review/founder evidence fail
  lint or report-lint as appropriate.
- High-risk retrospective tickets cannot disable review/human gates silently.
- Snapshot/report output exposes retrospective/audit-backfill state.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/tickets_workspace.bash lib/palari/agents_review_scope.bash tests/run-retrospective-governance.sh
- ./tests/run-retrospective-governance.sh

## Ticket Completion Contract

### Non-Goals

- Do not accept tickets.
- Do not merge, push, deploy, or create PRs.
- Do not change policy acceptance, broker behavior, evidence signing, adoption
  import behavior, runtime state, secrets, dependencies, or lockfiles.
- Do not backfill any existing historical tickets as part of this ticket.
- Do not weaken normal ticket acceptance, scope, review, or human authority
  rules.

### Definition Of Done

Retrospective/audit-backfill tickets are first-class and visibly different from
normal governed tickets, with lint/report/snapshot protections that make
high-risk retrospective work fail closed unless it carries explicit original
commit, bypass reason, reviewer, and founder evidence.

### Evidence Required

- Focused shell regression test.
- POS-0103 technical report, human report, CI evidence, scope-check,
  report-lint, and fresh-context reviewer note.

### Expansion Rules

- Stop or split if the change grows into automatic acceptance, historical ticket
  migration, merge/push/PR automation, policy acceptance, broker enforcement, or
  broad evidence-signing semantics.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
