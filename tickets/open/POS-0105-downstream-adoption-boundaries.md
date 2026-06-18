---
id: POS-0105
title: Downstream Adoption Boundaries
status: in-review
risk: R3
priority: P2
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-18T12:04:05Z
claim_ref: refs/palari/claims/POS-0105
claim_heartbeat_at: 2026-06-18T12:29:38Z
claim_expires_at: 2026-06-18T12:34:38Z
allowed_paths:
  - README.md
  - contracts/adoption.md
  - lib/palari/init_adopt.bash
  - tests/run-adoption.sh
  - tickets/open/POS-0105-*
  - tickets/closed/POS-0105-*
  - reports/POS-0105-technical-report.md
  - reports/POS-0105-reviewer-note.md
  - reports/human/POS-0105-human-report.md
  - reports/evidence/POS-0105/**
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
  - bash -n lib/palari/init_adopt.bash tests/run-adoption.sh
  - ./tests/run-adoption.sh
  - ./tests/run-cli-structure.sh
target_branch: ticket/POS-0104
branch: ticket/POS-0105
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0105 Downstream Adoption Boundaries

## Goal

Keep Palari adoption from activating upstream governance history in downstream
repositories. A newly adopted repo should get the Palari framework substrate,
not the source repo's closed tickets, reports, evidence, human reports, memory,
or project-specific self-test history.

## Scope

- Clarify the adoption path manifest and exclusions for downstream repos.
- Ensure non-dry-run adoption leaves downstream governance history clean by
  default.
- Add focused regression coverage in the adoption test harness.
- Document the downstream boundary in the adoption contract and README if needed.

## Acceptance

- Downstream adoption does not activate upstream closed tickets, reports,
  evidence bundles, human reports, project memory, or upstream self-test
  artifacts by default.
- Adoption plan/report output names the excluded upstream-owned governance
  artifacts.
- Upstream self-tests remain source-repo checks and are not treated as active
  downstream CI unless explicitly opted in later.
- Existing bootstrap/adoption plan approval, target/source drift checks, and
  doctor behavior remain intact.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/init_adopt.bash tests/run-adoption.sh
- ./tests/run-adoption.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not redesign adoption.
- Do not add hosted state, external services, or secrets.
- Do not change acceptance authority, broker behavior, policy acceptance,
  dependencies, lockfiles, deployment config, or runtime state.
- Do not add an explicit upstream-history import option unless the review proves
  it is required for this slice.

### Definition Of Done

- A target repo adopted from Palari starts with empty local governance history
  directories except framework `.gitkeep` scaffolding.
- The plan/report makes excluded upstream-owned governance artifacts visible.
- Regression tests prove closed tickets, reports, evidence, human reports, and
  memory from the source repo do not become active downstream history.

### Evidence Required

- `./tests/run-adoption.sh`
- `./tests/run-cli-structure.sh`
- POS-0105 CI evidence.
- Technical report, human report, and fresh-context reviewer note.

### Expansion Rules

- Stop and reopen if the change requires importing upstream history, changing
  acceptance authority, changing adoption approval semantics, or touching
  secrets/dependencies/deploy/runtime surfaces.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
