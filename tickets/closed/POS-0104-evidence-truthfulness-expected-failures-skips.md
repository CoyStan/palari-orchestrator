---
id: POS-0104
title: Evidence truthfulness expected failures skips
status: accepted
risk: R3
priority: P2
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-18T11:40:08Z
claim_ref: refs/palari/claims/POS-0104
claim_heartbeat_at: 2026-06-18T13:36:02Z
claim_expires_at: 2026-06-18T14:36:02Z
allowed_paths:
  - bin/palari
  - lib/palari/ci_accept.bash
  - lib/palari/evidence_quality.bash
  - lib/palari/evidence_truthfulness.bash
  - contracts/cli-maintainability.md
  - contracts/review-and-acceptance.md
  - README.md
  - tests/run-evidence-quality.sh
  - tests/palari_acceptance.bats
  - tickets/open/POS-0104-*
  - tickets/closed/POS-0104-*
  - reports/POS-0104-technical-report.md
  - reports/POS-0104-reviewer-note.md
  - reports/human/POS-0104-human-report.md
  - reports/evidence/POS-0104/**
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
  - bash -n lib/palari/ci_accept.bash lib/palari/evidence_truthfulness.bash lib/palari/evidence_quality.bash tests/run-evidence-quality.sh
  - ./tests/run-evidence-quality.sh
  - bats tests/palari_acceptance.bats
  - ./tests/run-cli-structure.sh
target_branch: ticket/POS-0103
branch: ticket/POS-0104
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-18T13:36:06Z
created: 2026-06-18
updated: 2026-06-18
---

# POS-0104 Evidence truthfulness expected failures skips

## Goal

Make Palari CI evidence honest when verification contains skips, TODO/FIXME-style
placeholders, or expected-failure style checks.

Green evidence must not hide deferred success criteria. Operators and reviewers
should be able to see whether a ticket's own acceptance evidence was actually
run, skipped as manual/descriptive, or deferred to a linked follow-up.

## Scope

- Extend Palari CI manifest/log output so skipped/manual/descriptive
  verification is counted and visible.
- Extend evidence scoring/readiness so skipped own-ticket verification is not
  silently treated as complete evidence.
- Keep `ci_accept.bash` under the existing structure limit by putting new helper
  logic in a focused evidence truthfulness module.
- Add focused regression coverage for passing evidence, skipped/manual evidence,
  and explicitly documented discovery/documentation exceptions.
- Document the evidence truthfulness rule in the review/acceptance contract and
  README.

## Acceptance

- `reports/evidence/TICKET/manifest.json` exposes skipped verification count and
  skipped/fixme metadata instead of only a broad passed/failed status.
- `./bin/palari evidence score TICKET --strict` fails or reports not-ready when
  a ticket's own verification was skipped and the ticket is not explicitly a
  test-discovery/documentation ticket.
- Skipped/manual/descriptive checks can remain allowed for discovery or
  documentation tickets, but the manifest and score must still show them.
- Existing all-passing CI evidence remains accepted.
- Existing evidence integrity checks, acceptance authority, claim freshness,
  hash validation, and stack behavior remain unchanged.

## Verification

- bash -n lib/palari/ci_accept.bash lib/palari/evidence_truthfulness.bash lib/palari/evidence_quality.bash tests/run-evidence-quality.sh
- ./tests/run-evidence-quality.sh
- bats tests/palari_acceptance.bats
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not redesign the whole evidence system.
- Do not change human acceptance authority or actor separation.
- Do not introduce broker/policy side effects.
- Do not require external CI, GitHub, secrets, deploys, dependencies, or
  lockfiles.

### Definition Of Done

- A ticket with ordinary passing automated verification can still reach ready
  evidence.
- A ticket whose own success criteria are represented only by skipped/manual
  checks cannot appear ready unless it is explicitly classified as
  documentation/test-discovery.
- Manifest/log/evidence score output names skipped/deferred state plainly.

### Evidence Required

- Focused automated regression tests.
- CI evidence refreshed for POS-0104.
- Technical and human reports.
- Fresh-context reviewer note.

### Expansion Rules

- Stop and reopen if the implementation requires changing acceptance authority,
  policy acceptance, broker behavior, deployment config, secrets, dependencies,
  or unrelated process surfaces.

### Final Review Gate

- Reviewer checks manifest truthfulness, evidence-score behavior, existing
  passing-ticket compatibility, and no authority weakening.
