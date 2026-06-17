---
id: POS-0099
title: Governed bootstrap adoption lifecycle
status: claimed
risk: R4
priority: P1
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-17T22:48:56Z
claim_ref: refs/palari/claims/POS-0099
claim_heartbeat_at: 2026-06-17T22:48:56Z
claim_expires_at: 2026-06-17T22:53:56Z
allowed_paths:
  - lib/palari/init_adopt.bash
  - tests/run-adoption.sh
  - tests/run-cli-structure.sh
  - README.md
  - contracts/adoption.md
  - docs/**
  - tickets/open/POS-0099-*
  - tickets/closed/POS-0099-*
  - reports/POS-0099-technical-report.md
  - reports/POS-0099-reviewer-note.md
  - reports/human/POS-0099-human-report.md
  - reports/evidence/POS-0099/**
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
  - ./tests/run-adoption.sh
  - ./tests/run-cli-structure.sh
target_branch: main
branch: ticket/POS-0099
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-17
updated: 2026-06-17
---

# POS-0099 Governed bootstrap adoption lifecycle

## Goal

Add a governed bootstrap/adoption plan step so Palari adoption writes are
previewable, reviewable, and human-approved before they mutate a target repo.

## Scope

- Add `palari adopt plan TARGET --out FILE` for a durable adoption artifact.
- Require an approved plan for non-dry-run `palari adopt TARGET`.
- Preserve dry-run adoption as the no-write preview path.
- Record source, target, path manifest, exclusions, and downstream boundaries.
- Update adoption docs and focused adoption tests.

## Acceptance

- Dry-run adoption still runs without a plan and does not write target files.
- Non-dry-run adoption without `--plan` fails closed with a clear command path.
- A generated plan starts as `status: proposed` and records source path,
  source ref, target path, target head, path manifest, exclusions, and
  downstream customization boundaries.
- A proposed plan is not enough to write files.
- An approved plan allows the existing adoption copy/init/doctor behavior.
- The plan source and target must match the current adoption command.
- README and adoption contract document the governed flow.
- Path and risk rules are respected.

## Verification

- ./tests/run-adoption.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement downstream artifact curation beyond recording exclusions in
  the plan. That is covered by the later downstream adoption boundary ticket.
- Do not change acceptance actor identity, retrospective ticket semantics,
  GitHub workflow preflight, broker behavior, policy behavior, secrets,
  dependencies, runtime state, push, merge, or deploy behavior.

### Definition Of Done

- The adoption command has a durable plan artifact and cannot perform a
  non-dry-run target write without a human-approved plan.

### Evidence Required

- Focused adoption and CLI structure tests.
- POS-0099 CI evidence, evidence score, scope check, report lint, technical
  report, human report, and fresh-context reviewer note.

### Expansion Rules

- Stop or split if this grows into downstream self-test curation, stable human
  identity, atomic closeout, retrospective governance, GitHub doctor, or
  multi-ticket scope-check UX.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
