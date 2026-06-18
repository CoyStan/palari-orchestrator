---
id: POS-0106
title: Scope Hygiene Generated Worktree Artifacts
status: claimed
risk: R3
priority: P2
stream: process
serves_goal: 
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-18T12:33:38Z
claim_ref: refs/palari/claims/POS-0106
claim_heartbeat_at: 2026-06-18T13:03:18Z
claim_expires_at: 2026-06-18T13:08:18Z
allowed_paths:
  - README.md
  - contracts/scope-and-paths.md
  - contracts/worktree-first.md
  - lib/palari/hygiene.bash
  - lib/palari/agents_review_scope.bash
  - lib/palari/tickets_workspace.bash
  - tests/run-hygiene.sh
  - tests/run-worktree-closeout.sh
  - tests/run-golden.sh
  - tests/run-cli-structure.sh
  - tickets/open/POS-0106-*
  - tickets/closed/POS-0106-*
  - reports/POS-0106-technical-report.md
  - reports/POS-0106-reviewer-note.md
  - reports/human/POS-0106-human-report.md
  - reports/evidence/POS-0106/**
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
  - bash -n lib/palari/hygiene.bash lib/palari/agents_review_scope.bash lib/palari/tickets_workspace.bash tests/run-hygiene.sh tests/run-worktree-closeout.sh tests/run-golden.sh
  - ./tests/run-hygiene.sh
  - ./tests/run-worktree-closeout.sh
  - ./tests/run-golden.sh
  - ./tests/run-cli-structure.sh
target_branch: ticket/POS-0105
branch: ticket/POS-0106
worktree: /home/quetza/palari-orchestrator-worktrees/palari-orchestrator-worktrees/palari-orchestrator-worktrees/palari-orchestrator-worktrees/palari-orchestrator-worktrees/palari-orchestrator-worktrees/palari-orchestrator-worktrees/POS-0106
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-18
updated: 2026-06-18
---

# POS-0106 Scope Hygiene Generated Worktree Artifacts

## Goal

Make generated/worktree artifacts a hygiene concern instead of something agents
solve by widening `allowed_paths`. Scope-check and worktree flows should make
tracked generated artifacts fail clearly, while untracked/generated dirt remains
classified as generated hygiene.

## Scope

- Harden generated artifact classification for local hygiene and ticket gates.
- Add or tighten warnings/errors for dangerous generated paths in ticket
  `allowed_paths`.
- Preserve worktree isolation while ensuring local generated artifacts do not
  become legitimate ticket scope.
- Add focused regression coverage for generated artifacts, tracked generated
  files, and generated-path `allowed_paths`.
- Update scope/worktree docs if needed.

## Acceptance

- Untracked generated artifacts such as `node_modules`, `dist`, build outputs,
  caches, and local worktree symlinks do not require `allowed_paths`.
- Tracked generated artifacts fail clearly instead of being treated as normal
  acceptable source changes.
- Dangerous generated paths in `allowed_paths` produce a lint error or strong
  warning so agents do not paper over hygiene problems by broadening scope.
- Existing scope-check, hygiene, worktree closeout, and golden flow behavior
  remains intact.
- Path and risk rules are respected.

## Verification

- bash -n lib/palari/hygiene.bash lib/palari/agents_review_scope.bash lib/palari/tickets_workspace.bash tests/run-hygiene.sh tests/run-worktree-closeout.sh tests/run-golden.sh
- ./tests/run-hygiene.sh
- ./tests/run-worktree-closeout.sh
- ./tests/run-golden.sh
- ./tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not redesign the ticket lifecycle, worktree layout, or acceptance model.
- Do not delete caches, node_modules, dist outputs, or user runtime files.
- Do not change dependencies, lockfiles, deployment config, runtime state,
  secrets, broker behavior, or policy acceptance.
- Do not make generated artifacts valid implementation scope.

### Definition Of Done

- Hygiene classifies generated/worktree artifacts separately from source dirt.
- Scope/lint behavior discourages or blocks generated artifact `allowed_paths`.
- Tracked generated artifacts have an explicit failing test path.
- Regression tests prove the intended generated/source distinction.

### Evidence Required

- `./tests/run-hygiene.sh`
- `./tests/run-worktree-closeout.sh`
- `./tests/run-golden.sh`
- `./tests/run-cli-structure.sh`
- POS-0106 CI evidence.
- Technical report, human report, and fresh-context reviewer note.

### Expansion Rules

- Stop and reopen if the fix requires changing acceptance authority, broadening
  generated artifacts into legitimate scope, deleting local artifacts, touching
  secrets/dependencies/deploy/runtime state, or rewriting worktree architecture.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
