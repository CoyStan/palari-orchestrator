---
id: POS-0102
title: Atomic evidence refresh acceptance preparation
status: in-review
risk: R3
priority: P2
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-18T06:50:36Z
claim_ref: refs/palari/claims/POS-0102
claim_heartbeat_at: 2026-06-18T07:31:54Z
claim_expires_at: 2026-06-18T07:36:54Z
allowed_paths:
  - bin/palari
  - lib/palari/ci_accept.bash
  - lib/palari/evidence_quality.bash
  - lib/palari/tickets_workspace.bash
  - contracts/worktree-first.md
  - README.md
  - tests/run-evidence-refresh.sh
  - tests/palari_acceptance.bats
  - tickets/open/POS-0102-*
  - tickets/closed/POS-0102-*
  - reports/POS-0102-technical-report.md
  - reports/POS-0102-reviewer-note.md
  - reports/human/POS-0102-human-report.md
  - reports/evidence/POS-0102/**
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
  - bash -n lib/palari/ci_accept.bash tests/run-evidence-refresh.sh
  - ./tests/run-evidence-refresh.sh
  - bats tests/palari_acceptance.bats
target_branch: ticket/POS-0101
branch: ticket/POS-0102
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0102 Atomic evidence refresh acceptance preparation

## Goal

Provide a transaction-style evidence refresh / acceptance-preparation path that
helps agents refresh CI evidence at the exact current implementation HEAD
without weakening human acceptance authority.

## Scope

- Add a supported command or subcommand for evidence refresh preparation.
- The workflow must verify the ticket checkout and branch context before writing
  evidence.
- It must refuse to proceed when unrelated source changes are present.
- It must refresh CI evidence for the requested ticket at the current HEAD and
  avoid obvious stale `head_sha` loops caused by evidence/report commits.
- It must distinguish stale evidence from non-evidence failures instead of
  blindly retrying or hiding failures.
- It must print exact next commands for moving to review, generating reviewer
  packets, and human acceptance.
- Update focused docs if needed.
- Add focused regression coverage.

## Acceptance

- A clean ticket worktree can refresh evidence at current HEAD without manual
  ad hoc steps.
- Dirty or unrelated source changes fail closed before evidence is rewritten.
- Stale evidence is detected and refreshable.
- Non-`head_sha` manifest failures are not blindly retried.
- Actor identity and human acceptance rules remain enforced after refresh.
- The workflow does not accept, merge, push, deploy, or bypass human authority.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/ci_accept.bash tests/run-evidence-refresh.sh
- ./tests/run-evidence-refresh.sh
- bats tests/palari_acceptance.bats

## Ticket Completion Contract

### Non-Goals

- Do not accept tickets.
- Do not merge, push, deploy, or create PRs.
- Do not change policy acceptance, broker behavior, adoption behavior, runtime
  state, secrets, dependencies, or lockfiles.
- Do not weaken acceptance authority, stable actor identity, R5 protections, or
  human quorum behavior.
- Do not make evidence refresh a general auto-fix for every failing CI/evidence
  condition.

### Definition Of Done

Agents have one supported local command or documented command path that prepares
evidence for acceptance at the current implementation HEAD, fails closed on
unrelated source changes or non-evidence failures, and leaves human acceptance as
the only real acceptance path.

### Evidence Required

- Focused shell regression test.
- POS-0102 technical report, human report, CI evidence, scope-check,
  report-lint, and fresh-context reviewer note.

### Expansion Rules

- Stop or split if the change grows into acceptance automation, merge/push/PR
  automation, GitHub workflow changes, policy acceptance, or broader evidence
  scoring semantics.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.

## Ticket Completion Contract

### Non-Goals

- Nearby work this ticket must not absorb.

### Definition Of Done

- Concrete done condition.

### Evidence Required

- Report, command, review, screenshot, or manual check to inspect.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
