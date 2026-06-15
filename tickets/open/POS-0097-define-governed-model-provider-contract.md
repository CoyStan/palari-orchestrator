---
id: POS-0097
title: Define governed model provider contract
status: open
risk: R3
priority: P3
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - contracts/**
  - docs/integration/**
  - adapters/openrouter/**
  - tests/run-model-routing.sh
  - tests/run-openrouter.sh
  - tickets/open/POS-0097-define-governed-model-provider-contract.md
  - reports/POS-0097-technical-report.md
  - reports/POS-0097-reviewer-note.md
  - reports/human/POS-0097-human-report.md
  - reports/evidence/POS-0097/**
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
  - ./tests/run-model-routing.sh
  - ./tests/run-openrouter.sh
target_branch: main
branch: ticket/POS-0097
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0097 Define governed model provider contract

## Goal

Define a governed model provider contract so OpenRouter and future model
suppliers remain replaceable model supply, not Palari's authority layer,
policy engine, reviewer, acceptance gate, or hidden routing owner.

## Scope

- Document the model provider governance boundary.
- Define routing factors: risk, data sensitivity, cost, latency, task type,
  historical success, allowed providers, customer data restrictions, evaluation
  score, and fallback availability.
- Add focused assertions to model/OpenRouter tests so routing remains
  subordinate to Palari authority.
- Touch OpenRouter adapter code only if needed to keep existing contract tests
  coherent; no live provider behavior should be added.

## Acceptance

- The contract says model providers supply model capability and must not decide
  authority.
- The contract says routing policy is subordinate to Palari ticket, risk,
  policy, broker, data, and human-governance boundaries.
- The contract covers risk, data sensitivity, cost, latency, task type,
  historical success, allowed providers, customer data restrictions, evaluation
  score, and fallback availability.
- The contract says OpenRouter remains model supply, not governance.
- No real provider change, network dependency, credential path, dependency,
  lockfile, or side-effecting integration is added.
- Path and risk rules are respected.

## Verification

- ./tests/run-model-routing.sh
- ./tests/run-openrouter.sh

## Ticket Completion Contract

### Non-Goals

- Do not change model routing runtime behavior unless needed for test wording.
- Do not add live model provider calls, credentials, dependencies, lockfiles, or
  hosted service behavior.
- Do not let model providers accept work, grant authority, decide policy,
  bypass data restrictions, or replace human/fresh-context review.
- Do not change broker behavior, policy acceptance, HGL scoring, R5 controls,
  ticket lifecycle, deployment, secrets, or runtime state.

### Definition Of Done

- The model provider governance contract is documented and focused tests assert
  the key subordinate-authority routing language.

### Evidence Required

- Technical report, reviewer note, and human report.
- CI evidence bundle under `reports/evidence/POS-0097/`.
- Output from ticket lint, report lint, scope check, CI, and evidence score.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
