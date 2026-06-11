---
id: POS-0052
title: Fix README asset archive packaging
status: accepted
risk: R1
priority: P1
stream: docs
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T21:38:17Z
claim_ref: refs/palari/claims/POS-0052
claim_heartbeat_at: 2026-06-11T22:46:25Z
claim_expires_at: 2026-06-11T22:51:25Z
allowed_paths:
  - .gitattributes
  - README.md
  - assets/readme/**
  - tests/run-readme-assets.sh
  - .github/workflows/**
  - CHANGELOG.md
  - tickets/open/POS-0052*
  - tickets/closed/POS-0052*
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
requires_human_confirmation: false
requires_review: true
required_reports:
  - technical
verification:
  - tests/run-readme-assets.sh
  - shellcheck -x tests/run-readme-assets.sh
target_branch: main
branch: ticket/POS-0052
worktree: 
accepted_by: quetza
accepted_at: 2026-06-11T22:46:29Z
created: 2026-06-11
updated: 2026-06-11
---

# POS-0052 Fix README asset archive packaging

## Goal

Prevent portable release/source archives from shipping a README with broken
images. README-referenced `assets/readme/*` files should exist in the repo and
must not be excluded by `.gitattributes`.

## Scope

- `.gitattributes` release archive rules.
- README asset references only if needed.
- `tests/run-readme-assets.sh` and workflow wiring for the regression.

## Acceptance

- Every README `assets/readme/*` reference exists.
- README-referenced assets are not marked `export-ignore`.
- The regression test is wired into CI.
- Path and risk rules are respected.

## Verification

- tests/run-readme-assets.sh
- shellcheck -x tests/run-readme-assets.sh

## Ticket Completion Contract

### Non-Goals

- Redesigning README visuals.
- Replacing the dashboard or README marketing content.
- Changing release archive policy for governance history.

### Definition Of Done

- `assets/readme/*.png` is no longer blanket export-ignored.
- CI catches missing or export-ignored README asset references.

### Evidence Required

- `reports/POS-0052-technical-report.md`.
- Palari CI evidence bundle.
- Fresh reviewer note recommending accept, reopen, or needs-human.

### Expansion Rules

- Stop if the fix requires changing the release packaging model beyond README
  assets or replacing current visual assets.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
