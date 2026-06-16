---
id: POS-0098
title: Dogfood current main Palari Orchestrator workflow
status: accepted
risk: R2
priority: P1
stream: process
serves_goal: GOAL-0200
model_hint: 
claimed_by: Codex
claimed_at: 2026-06-16T15:23:27Z
claim_ref: refs/palari/claims/POS-0098
claim_heartbeat_at: 2026-06-16T15:24:55Z
claim_expires_at: 2026-06-16T15:39:55Z
allowed_paths:
  - STATE.md
  - docs/autonomy/dogfooding-workflow.md
  - lib/palari/prompt.bash
  - tests/run-prompt.sh
  - tests/run-state.sh
  - tickets/open/POS-0098-*
  - tickets/closed/POS-0098-*
  - reports/POS-0098-technical-report.md
  - reports/POS-0098-reviewer-note.md
  - reports/human/POS-0098-human-report.md
  - reports/evidence/POS-0098/**
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
required_reports:
  - human
verification:
  - test -f docs/autonomy/dogfooding-workflow.md
  - grep -q 'current base is main' docs/autonomy/dogfooding-workflow.md
  - grep -q 'after context compaction' docs/autonomy/dogfooding-workflow.md
  - ./tests/run-prompt.sh
  - ./tests/run-state.sh
target_branch: main
branch: ticket/POS-0098
worktree: 
accepted_by: founder
acceptance_mode: human
accepted_at: 2026-06-16T15:33:33Z
created: 2026-06-16
updated: 2026-06-16
---

# POS-0098 Dogfood current main Palari Orchestrator workflow

## Goal

Make future Palari Orchestrator work start from the current accepted mainline
instead of stale stacked worktrees or memory from the POS-0097 integration
branch. The result should give compacted/fresh agents a concise reorientation
note and a tiny prompt reminder for long-running work.

## Scope

- Add a dogfooding workflow note for current-main Palari Orchestrator work.
- Update the repo state map so collaborators can find that note.
- Add a tiny `palari prompt long-run` orientation reminder.
- Add focused prompt/state test coverage for the changed text.
- Add POS-0098 reports and evidence.

## Acceptance

- The note says the current base is main after POS-0097 merged.
- The note explains that old POS-0097 worktree/branch guidance is obsolete.
- The note answers how a fresh agent reorients after context compaction.
- The note documents the current ticket loop: status, ticket creation,
  evidence refresh, fresh-context review, human acceptance, and explicit
  push/merge expectations.
- The note lists manual habits to avoid, especially hand-editing lifecycle
  state or continuing from stale worktrees.
- Any prompt/help text update is tiny, read-only, and tested.
- No broker behavior, policy acceptance behavior, human quorum behavior,
  ticket acceptance rules, dependencies, secrets, runtime state, external
  side effects, push/merge behavior, or deployment behavior changes.
- Path and risk rules are respected.

## Verification

- `test -f docs/autonomy/dogfooding-workflow.md`
- `grep -q 'current base is main' docs/autonomy/dogfooding-workflow.md`
- `grep -q 'after context compaction' docs/autonomy/dogfooding-workflow.md`
- `./tests/run-prompt.sh`
- `./tests/run-state.sh`

## Ticket Completion Contract

### Non-Goals

- Do not implement autonomous runners, broker behavior, model-provider
  behavior, memory providers, policy acceptance, human quorum changes, ticket
  acceptance rules, dependencies, secrets, runtime state, external service
  calls, deploys, pushes, or merges.
- Do not accept POS-0098.
- Do not revive the old `ticket/POS-0097` base guidance.
- Do not delete, clean, reset, or rewrite unrelated worktrees.

### Definition Of Done

- A future agent can read one note and know how to continue Palari Orchestrator
  work from current `main` after POS-0097 merged.
- `palari prompt long-run` reminds compacted agents to inspect state, run a
  dry-run queue plan, and verify branch/base before editing.

### Evidence Required

- Technical report, human report, and fresh-context reviewer note.
- CI evidence bundle under `reports/evidence/POS-0098/`.
- Output from ticket lint, report lint, scope check, focused tests, CI, and
  evidence score.

### Expansion Rules

- Stop if the fix needs lifecycle semantics, acceptance behavior, broker
  behavior, policy behavior, quorum behavior, secrets, dependencies, runtime
  state, push/merge behavior, or broader CLI redesign.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.

- test -f docs/autonomy/dogfooding-workflow.md
- grep -q 'current base is main' docs/autonomy/dogfooding-workflow.md
- grep -q 'after context compaction' docs/autonomy/dogfooding-workflow.md
- ./tests/run-prompt.sh
- ./tests/run-state.sh

## Ticket Completion Contract

### Non-Goals

- Nearby work this ticket must not absorb.

### Definition Of Done

- Concrete done condition.

### Evidence Required

- Report, command, review, screenshot, or manual check to inspect.

### Expansion Rules

- Stop if scope, risk, or authority changes.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
