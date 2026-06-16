---
id: POS-0096
title: Define governed memory provider contract
status: accepted
risk: R3
priority: P3
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-15T16:49:37Z
claim_ref: refs/palari/claims/POS-0096
claim_heartbeat_at: 2026-06-16T13:43:20Z
claim_expires_at: 2026-06-16T13:48:20Z
allowed_paths:
  - contracts/**
  - docs/integration/**
  - memory/**
  - tests/run-memory.sh
  - tickets/open/POS-0096-define-governed-memory-provider-contract.md
  - reports/POS-0096-technical-report.md
  - reports/POS-0096-reviewer-note.md
  - reports/human/POS-0096-human-report.md
  - reports/evidence/POS-0096/**
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
  - ./tests/run-memory.sh
target_branch: main
branch: ticket/POS-0096
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-16T13:46:59Z
created: 2026-06-15
updated: 2026-06-16
---

# POS-0096 Define governed memory provider contract

## Goal

Define a governed memory provider contract so future GBrain or other memory
systems can supply context to Palari-governed work without becoming an
authority layer, acceptance gate, credential owner, or hidden source of truth.

## Scope

- Document the memory provider boundary for company OS work.
- Define the allowed memory provider operations: search, synthesize, cite,
  check ACL, report gaps, and propose writes.
- Define the Palari-owned controls around actor access, citations, freshness,
  write review, and data class routing to model/providers.
- Add focused assertions to the memory test so the boundary cannot silently
  disappear.
- Touch memory adapter code only if needed to keep existing memory contract
  tests coherent; no live provider integration should be added.

## Acceptance

- The contract says memory providers are context suppliers, not authority.
- The contract covers `memory.search`, `memory.synthesize`, `memory.cite`,
  `memory.check_acl`, `memory.report_gaps`, and `memory.propose_write`.
- The contract says Palari controls which actor may query which memory, whether
  citations are required, whether memory is fresh enough, whether writes require
  review, and what data class may be sent to which model/provider.
- The contract leaves room for GBrain without adding a live GBrain dependency.
- No real memory provider, hosted call, credential path, dependency, lockfile,
  or side-effecting write integration is added.
- Path and risk rules are respected.

## Verification

- ./tests/run-memory.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement GBrain or any live memory provider.
- Do not add network calls, credentials, dependencies, lockfiles, hosted
  services, or side-effecting memory writes.
- Do not let memory providers accept work, grant authority, bypass ACLs,
  replace evidence, or mutate lifecycle state.
- Do not change policy acceptance, broker behavior, HGL scoring, R5 controls,
  ticket lifecycle, deployment, or runtime state.

### Definition Of Done

- The memory provider contract is documented and focused tests assert the key
  governance-boundary language.

### Evidence Required

- Technical report, reviewer note, and human report.
- CI evidence bundle under `reports/evidence/POS-0096/`.
- Output from ticket lint, report lint, scope check, CI, and evidence score.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
