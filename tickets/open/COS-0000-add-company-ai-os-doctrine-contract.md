---
id: COS-0000
title: Add company AI OS doctrine contract
status: claimed
risk: R2
priority: P2
stream: process
serves_goal: GOAL-0100
model_hint:
claimed_by: codex
claimed_at: 2026-06-14T22:08:04Z
claim_ref: refs/palari/claims/COS-0000
claim_heartbeat_at: 2026-06-14T22:10:14Z
claim_expires_at: 2026-06-14T22:15:14Z
allowed_paths:
  - contracts/**
  - docs/**
  - goals/**
  - STATE.md
  - CHANGELOG.md
  - tickets/open/COS-0000*
  - tickets/closed/COS-0000*
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
  - test -s contracts/company-ai-os.md
  - grep -Fq 'Human Governance Load' contracts/company-ai-os.md
  - grep -Fq 'broker' contracts/company-ai-os.md
  - ./tests/run-state.sh
target_branch: main
branch: ticket/COS-0000
worktree:
accepted_by:
accepted_at:
created: 2026-06-14
updated: 2026-06-14
---

# COS-0000 Add company AI OS doctrine contract

## Goal

Record the Company AI OS doctrine and first roadmap boundary as a repo-native
contract without changing runtime behavior.

## Scope

- Add `contracts/company-ai-os.md`.
- Create or reuse the umbrella goal required by the roadmap.
- Update `STATE.md` planned work and `CHANGELOG.md`.

## Acceptance

- The contract states that Palari is the authority layer, not the agent.
- The contract states that the repo remains the source of truth.
- The contract makes Human Governance Load first-class.
- The contract keeps policy acceptance simulation-only for the initial batch.
- The contract states that broker work starts mock/read-only and controls side
  effects.
- The contract records R5 as governance/kernel protection.
- No runtime behavior changes.

## Verification

- test -s contracts/company-ai-os.md
- grep -Fq 'Human Governance Load' contracts/company-ai-os.md
- grep -Fq 'broker' contracts/company-ai-os.md
- ./tests/run-state.sh

## Ticket Completion Contract

### Non-Goals

- Do not implement R5 validation yet.
- Do not add workflow, human, policy, broker, or outcome CLIs yet.
- Do not change executor, acceptance, merge, push, deploy, or side-effect
  behavior.

### Definition Of Done

- `contracts/company-ai-os.md` exists and includes the doctrine.
- `STATE.md` points collaborators to the Company AI OS plan.
- `CHANGELOG.md` records the contract addition.
- Required checks pass or failures are recorded.

### Evidence Required

- Technical report.
- Reviewer note.
- Verification commands listed in this ticket.

### Expansion Rules

- Stop if implementation requires runtime behavior or authority changes.
- Use a later ticket for R5 enforcement, workflow artifacts, HGL scoring,
  policy simulation, broker evidence, or outcomes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
