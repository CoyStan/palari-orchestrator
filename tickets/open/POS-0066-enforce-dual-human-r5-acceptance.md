---
id: POS-0066
title: Enforce configurable human acceptance quorum
status: in-review
risk: R5
priority: P0
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: codex
claimed_at: 2026-06-15T12:04:21Z
claim_ref: refs/palari/claims/POS-0066
claim_heartbeat_at: 2026-06-15T20:36:09Z
claim_expires_at: 2026-06-16T20:36:09Z
allowed_paths:
  - lib/palari/ci_accept.bash
  - lib/palari/dashboard_snapshot.bash
  - lib/palari/evidence_quality.bash
  - lib/palari/init_adopt.bash
  - lib/palari/humans.bash
  - adapters/snapshot/fast_snapshot.py
  - adapters/planning/governance_debt.py
  - palari.config.yaml
  - schemas/palari.config.schema.json
  - contracts/adapters.md
  - contracts/company-ai-os.md
  - contracts/human-governance.md
  - contracts/human-governance-load.md
  - contracts/policy-acceptance.md
  - contracts/signed-acceptance.md
  - README.md
  - tests/palari_acceptance.bats
  - tests/run-secure-doctor.sh
  - tests/run-risks.sh
  - tests/run-human-governance-load.sh
  - tickets/open/POS-0066-enforce-dual-human-r5-acceptance.md
  - tickets/closed/POS-0066-enforce-dual-human-r5-acceptance.md
  - reports/POS-0066-technical-report.md
  - reports/POS-0066-reviewer-note.md
  - reports/human/POS-0066-human-report.md
  - reports/POS-0067-technical-report.md
  - reports/POS-0067-reviewer-note.md
  - reports/human/POS-0067-human-report.md
  - tickets/open/POS-0077-add-human-governance-debt-report.md
  - reports/POS-0077-technical-report.md
  - reports/POS-0077-reviewer-note.md
  - reports/human/POS-0077-human-report.md
  - reports/evidence/POS-0066/**
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
  - ./tests/run-risks.sh
  - ./tests/run-secure-doctor.sh
  - ./tests/run-gate-kernel.sh
  - ./tests/run-human-governance-load.sh
target_branch: ticket/POS-0065
branch: ticket/POS-0066
worktree: 
accepted_by:
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0066 Enforce configurable human acceptance quorum

## Goal

Make human acceptance requirements configurable by risk tier, so solo-founder
repositories can require one active authorized human for R5 while teams can
raise R5 or other risks to two or more human approvals.

## Scope

- Replace rigid R5 dual-human acceptance with
  `governance.required_human_approvals`.
- Preserve legacy `governance.r5_requires_dual_human: true` as a compatibility
  fallback.
- Keep policy acceptance simulation-only and ForgeGate separate from human
  approval.

## Acceptance

- `palari accept` validates the configured human-profile quorum for the ticket
  risk.
- R5 quorum `1` requires one active R5-authorized profile.
- R5 quorum `2` requires two distinct active R5-authorized profiles via
  `--by` and `--co-by`.
- Status, snapshot, evidence score, secure doctor, docs, and tests describe
  the same rule.
- Path and risk rules are respected.

## Verification

- ./tests/run-risks.sh
- ./tests/run-secure-doctor.sh
- ./tests/run-gate-kernel.sh
- ./tests/run-human-governance-load.sh

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
