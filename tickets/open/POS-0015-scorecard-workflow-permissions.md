---
id: POS-0015
title: Fix Scorecard workflow permissions
status: open
risk: R1
priority: P1
stream: governance
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - .github/workflows/scorecard.yml
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: false
verification:
  - actionlint
target_branch: main
branch: ticket/POS-0015
worktree:
accepted_by:
accepted_at:
created: 2026-06-07
updated: 2026-06-07
---

# POS-0015 Fix Scorecard workflow permissions

## Goal

Make the OpenSSF Scorecard workflow publish successfully by complying with
Scorecard's workflow permission restrictions.

## Scope

- Move write permissions from workflow scope to the Scorecard job.
- Keep SARIF upload and Scorecard publishing enabled.

## Acceptance

- `actionlint` passes.
- Palari CI passes for this ticket.
- The Scorecard workflow no longer has workflow-level write permissions.

## Verification

- actionlint

## Ticket Completion Contract

### Non-Goals

- Do not change Scorecard scoring policy.
- Do not change branch protection.
- Do not change other workflows.

### Definition Of Done

- The workflow uses read-only global permissions and job-scoped write
  permissions for Scorecard publishing and SARIF upload.

### Evidence Required

- Local lint and Palari CI evidence from the outer gate command.

### Expansion Rules

- Stop if fixing this requires repository settings or credential changes.

### Final Review Gate

- Confirm the change matches the observed Scorecard publishing failure.
