---
id: DSH-0001
title: Add company governance cards to console
status: accepted
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T23:27:08Z
claim_ref: refs/palari/claims/DSH-0001
claim_heartbeat_at: 2026-06-14T23:38:43Z
claim_expires_at: 2026-06-14T23:43:43Z
allowed_paths:
  - adapters/web/**
  - adapters/snapshot/**
  - tests/**
  - assets/**
  - README.md
  - STATE.md
  - CHANGELOG.md
  - tickets/open/DSH-0001*
  - tickets/closed/DSH-0001*
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
verification:
  - ./tests/run-dashboard-rubric.sh
  - ./bin/palari web --check >/tmp/palari-web-check.json
target_branch: main
branch: ticket/DSH-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-14T23:39:14Z
created: 2026-06-14
updated: 2026-06-14
---

# DSH-0001 Add company governance cards to console

## Goal

Render read-only Company Governance cards in the local operator console using
the `company_os` snapshot section.

## Scope

- Add a console support panel for Company Governance.
- Render workflow counts, open HGL, active human profile count, R3/R4/R5
  decision counts, missing-skill count, and active workflow gate rows.
- Keep the panel read-only: no accept, merge, push, deploy, policy activation,
  broker execution, or external side-effect controls.
- Extend dashboard rubric coverage for the new surface.
- Update state/changelog/reports.

## Acceptance

- The console renders a Company Governance panel from `snapshot.company_os`.
- Empty Company OS state renders gracefully.
- Populated Company OS state has stable row/metric rendering.
- Dashboard structure, accessibility, contrast, and snapshot-contract checks
  pass.
- `palari web --check` still returns valid snapshot JSON.
- Path and risk rules are respected.

## Verification

- ./tests/run-dashboard-rubric.sh
- ./bin/palari web --check >/tmp/palari-web-check.json

## Ticket Completion Contract

### Non-Goals

- Do not add browser-side accept, merge, push, deploy, policy activation, or
  broker write controls.
- Do not change snapshot semantics, HGL scoring, policy behavior, broker
  behavior, ticket lifecycle, or external systems.
- Do not redesign the console.

### Definition Of Done

- Company Governance panel is present in `index.html`.
- `renderCompanyGovernance` renders the new snapshot fields.
- CSS keeps metrics and workflow rows compact and responsive.
- Dashboard rubric verifies the surface.

### Evidence Required

- Technical report.
- Reviewer note.
- Dashboard rubric output.
- `web --check` output.
- CI evidence bundle for DSH-0001.

### Expansion Rules

- Stop if the work requires lifecycle mutation, policy activation, broker
  behavior, credentials, external calls, or a larger console redesign.

### Final Review Gate

- Reviewer confirms the panel is read-only, snapshot-driven, and does not add
  mutation authority before recommending accept, reopen, or needs-human.
