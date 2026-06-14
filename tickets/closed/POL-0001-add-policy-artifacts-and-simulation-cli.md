---
id: POL-0001
title: Add policy artifacts and simulation CLI
status: accepted
risk: R5
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint: 
claimed_by: codex
claimed_at: 2026-06-14T23:40:22Z
claim_ref: refs/palari/claims/POL-0001
claim_heartbeat_at: 2026-06-14T23:56:49Z
claim_expires_at: 2026-06-15T00:01:49Z
allowed_paths:
  - contracts/**
  - templates/**
  - policies/**
  - lib/palari/**
  - adapters/planning/**
  - bin/palari
  - palari.config.yaml
  - schemas/palari.config.schema.json
  - tests/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/POL-0001*
  - tickets/closed/POL-0001*
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
requires_human_confirmation: true
requires_review: true
verification:
  - ./tests/run-policy-simulation.sh
  - ./tests/run-evidence-quality.sh
target_branch: main
branch: ticket/POL-0001
worktree: 
accepted_by: quetza
accepted_at: 2026-06-14T23:56:59Z
created: 2026-06-14
updated: 2026-06-14
---

# POL-0001 Add policy artifacts and simulation CLI

## Goal

Introduce policy acceptance infrastructure in simulation-only mode so Palari
can explain whether a ticket would satisfy a proposed or active policy without
accepting the ticket or mutating lifecycle state.

## Scope

- Policy directories, template, and policy acceptance contract.
- Config/default keys for policy artifact directories.
- `palari policy create|list|show|lint`.
- `palari policy simulate TICKET-ID [--json]`.
- Focused tests and reports.

## Acceptance

- Policy lint works for proposed, active, and revoked artifacts.
- Policy simulation explains `would_accept` and `would_not_accept`.
- R5 tickets are never policy-eligible.
- Unknown conditions fail closed during simulation.
- No command can accept by policy yet.

## Verification

- ./tests/run-policy-simulation.sh
- ./tests/run-evidence-quality.sh

## Ticket Completion Contract

### Non-Goals

- Real policy acceptance.
- Policy activation lifecycle beyond manual artifact state.
- Policy candidate detection.
- Broker execution or side effects.
- Browser controls for policy mutation.

### Definition Of Done

- Policy artifacts and CLI are present.
- Simulation is deterministic and read-only.
- Tests cover acceptance simulation, refusal simulation, R5 refusal, unknown
  condition refusal, and unsupported policy acceptance.

### Evidence Required

- Technical report.
- Human/founder report.
- Fresh-context reviewer note.
- CI/evidence bundle.

### Expansion Rules

- Stop if real policy acceptance, ticket mutation, merge, push, deploy, broker,
  credentials, or production write behavior becomes necessary.

### Final Review Gate

- Reviewer confirms all policy commands are simulation-only, no R5 policy
  acceptance path exists, and verification passes.
