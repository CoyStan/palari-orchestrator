---
id: POS-0091
title: Add migration helper for human capacity fields
status: open
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - lib/palari/humans.bash
  - adapters/planning/**
  - tests/run-human-governance.sh
  - tickets/open/POS-0091-add-migration-helper-for-human-capacity-fields.md
  - reports/POS-0091-technical-report.md
  - reports/POS-0091-reviewer-note.md
  - reports/human/POS-0091-human-report.md
  - reports/evidence/POS-0091/**
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
  - ./bin/palari human lint
  - ./tests/run-human-governance.sh
target_branch: main
branch: ticket/POS-0091
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0091 Add migration helper for human capacity fields

## Goal

Add a deterministic human capacity-field migration helper so repos can detect
and migrate old `capacity_*` human governance fields to the newer operational
capacity fields without silently changing human authority or lifecycle state.

## Scope

- Add `./bin/palari human migrate-capacity --check`.
- Add `./bin/palari human migrate-capacity --write`.
- Update the human governance tests for no-side-effect check mode,
  deterministic write mode, and dirty-repo refusal.
- Keep the existing human lint compatibility with old capacity fields until
  migration is explicitly run.

## Acceptance

- `--check` reports profiles that still use deprecated `capacity_*` fields and
  exits without modifying files.
- `--write` migrates human profiles deterministically to the current fields.
- `--write` refuses to modify a dirty repo unless an existing Palari hygiene
  pattern explicitly allows it.
- Migration does not adopt, revoke, create, or otherwise change human profile
  lifecycle or authority.
- Existing profiles and tests remain lint-compatible before migration.
- Path and risk rules are respected.

## Verification

- ./bin/palari human lint
- ./tests/run-human-governance.sh

## Ticket Completion Contract

### Non-Goals

- Do not change HGL scoring, workflow planning, authority ceilings, R5 policy
  rules, or policy simulation behavior.
- Do not remove compatibility for old capacity fields from human lint.
- Do not migrate repository fixtures outside the focused test sandbox.
- Do not add dependencies, secrets, runtime state, deployment changes, or side
  effects.

### Definition Of Done

- `palari human migrate-capacity --check` and `--write` exist, are documented
  in command help, and are covered by focused human governance tests.

### Evidence Required

- Technical report, reviewer note, and human report.
- CI evidence bundle under `reports/evidence/POS-0091/`.
- Output from ticket lint, report lint, scope check, CI, and evidence score.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
