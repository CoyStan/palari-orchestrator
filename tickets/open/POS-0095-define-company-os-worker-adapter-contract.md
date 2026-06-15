---
id: POS-0095
title: Define company OS worker adapter contract
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
  - adapters/**
  - tests/run-agent-wrapper.sh
  - tickets/open/POS-0095-define-company-os-worker-adapter-contract.md
  - reports/POS-0095-technical-report.md
  - reports/POS-0095-reviewer-note.md
  - reports/human/POS-0095-human-report.md
  - reports/evidence/POS-0095/**
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
  - ./tests/run-agent-wrapper.sh
target_branch: main
branch: ticket/POS-0095
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-15
updated: 2026-06-15
---

# POS-0095 Define company OS worker adapter contract

## Goal

Define a company OS external worker adapter contract so future Hermes, GBrain,
OpenRouter, Codex, local agents, and human-delegate integrations have a clear
Palari authority boundary before any real integration or network dependency is
added.

## Scope

- Extend contracts/docs for company OS worker adapters.
- Cover worker types such as coding agents, research agents, review agents,
  memory providers, model providers, workflow executors, and human delegates.
- Add focused assertions to the existing agent wrapper test so the contract
  cannot silently lose the key authority boundaries.
- Touch adapter code only if needed to keep existing wrapper contract tests
  coherent; no real integration should be added.

## Acceptance

- The contract says external workers may receive scoped work packets, produce
  outputs/logs/evidence, and request broker actions.
- The contract says external workers may not hold company credentials directly.
- The contract says external workers may not accept work.
- The contract says external workers may not merge, deploy, send, charge, or
  refund unless a broker permits and records the action.
- The contract requires workers to declare model, provider, and runtime.
- The contract requires Palari-auditable evidence and logs.
- The contract covers future Hermes, GBrain, OpenRouter, Codex, local agents,
  and human delegates.
- No real integration, credential path, network dependency, hosted service, or
  side-effecting connector is added.
- Path and risk rules are respected.

## Verification

- ./tests/run-agent-wrapper.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement Hermes, GBrain, OpenRouter, Slack, Gmail, Stripe, CRM, cloud,
  production, or hosted worker integration.
- Do not add credentials, secrets, network calls, dependencies, lockfiles, or
  side-effecting broker behavior.
- Do not grant workers acceptance, merge, deploy, send, charge, refund, or
  policy authority.
- Do not change ticket lifecycle, HGL scoring, R5 controls, policy simulation,
  or broker runtime behavior.

### Definition Of Done

- The worker adapter contract is documented and focused tests assert the key
  authority-boundary language.

### Evidence Required

- Technical report, reviewer note, and human report.
- CI evidence bundle under `reports/evidence/POS-0095/`.
- Output from ticket lint, report lint, scope check, CI, and evidence score.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
