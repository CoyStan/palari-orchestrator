---
id: POS-0081
title: Add HGL calibration report from outcomes
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
  - adapters/planning/**
  - lib/palari/**
  - contracts/human-governance-load.md
  - contracts/outcomes.md
  - tests/run-human-governance-load.sh
  - tests/run-outcomes.sh
  - tickets/open/POS-0081-add-hgl-calibration-report-from-outcomes.md
  - reports/POS-0081-technical-report.md
  - reports/POS-0081-reviewer-note.md
  - reports/human/POS-0081-human-report.md
  - reports/evidence/POS-0081/**
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
  - ./tests/run-human-governance-load.sh
  - ./tests/run-outcomes.sh
target_branch: main
branch: ticket/POS-0081
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0081 Add HGL calibration report from outcomes

## Goal

Add a read-only HGL calibration report that learns from recorded outcomes and
suggests where future human-approved HGL/risk/policy calibration may be useful.

## Scope

- Add a `palari burden calibrate` command with text and JSON output.
- Read recorded outcome impact fields to compare predicted vs actual HGL/risk.
- Surface policy-candidate and evidence-burden reduction patterns as suggestions.
- Document that calibration is advisory only and never changes weights/policies.
- Add focused tests for the new report and outcome-driven calibration fields.

## Acceptance

- `palari burden calibrate` reports overestimated HGL, underestimated HGL, risk
  mismatches, policy candidates, and evidence patterns from recorded outcomes.
- `palari burden calibrate --json` exposes deterministic structured output.
- The report explicitly states that no HGL weights, risk tiers, or policies were
  changed automatically.
- Existing outcome records remain compatible when impact fields are absent.
- Path and risk rules are respected.

## Verification

- ./tests/run-human-governance-load.sh
- ./tests/run-outcomes.sh

## Ticket Completion Contract

### Non-Goals

- Do not change HGL scoring weights or coverage rules automatically.
- Do not accept or activate policies.
- Do not change workflow, human, broker, snapshot, or product behavior beyond the
  read-only report.

### Definition Of Done

- The command, tests, contracts, reports, and evidence exist and pass normal
  Palari ticket checks.

### Evidence Required

- Text and JSON calibration command output.
- Focused human-governance-load and outcomes test output.
- Ticket lint, report lint, scope check, CI, and evidence score output.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
