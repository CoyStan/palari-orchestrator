---
id: POS-0054
title: Add mock-agent refusal demo
status: in-review
risk: R2
priority: P1
stream: demo
serves_goal: 
claimed_by: codex
claimed_at: 2026-06-11T22:05:21Z
claim_ref: refs/palari/claims/POS-0054
claim_heartbeat_at: 2026-06-11T22:08:41Z
claim_expires_at: 2026-06-11T22:13:41Z
allowed_paths:
  - bin/palari
  - lib/palari/demo.bash
  - lib/palari/agents_review_scope.bash
  - README.md
  - tests/run-demo.sh
  - tests/run-agent-mock.sh
  - CHANGELOG.md
  - tickets/open/POS-0054*
  - tickets/closed/POS-0054*
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
  - tests/run-demo.sh
  - tests/run-agent-mock.sh
  - shellcheck -x bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh
target_branch: main
branch: ticket/POS-0054
worktree: 
accepted_by:
accepted_at:
created: 2026-06-11
updated: 2026-06-11
---

# POS-0054 Add mock-agent refusal demo

## Goal

Make the deterministic mock-agent refusal behavior easy to demonstrate without
running a real AI tool. The demo should show a forbidden `.env` write attempt,
scope-check refusal, preserved executor evidence, and no browser-side or
acceptance-side mutation.

## Scope

- Add a `palari demo --agent-refusal` fixture path.
- Create a local `DEM-0003` blocked ticket, handoff, and executor evidence
  under `reports/evidence/DEM-0003/executor/mock`.
- Document the fixture in the README and CLI help.
- Extend demo tests so the fixture is generated, linted, and force-replaceable.

## Acceptance

- `palari demo --agent-refusal` writes a blocked `DEM-0003` refusal fixture.
- The fixture records a mock `.env` attempt and scope-check refusal evidence.
- Re-running without `--force` refuses to overwrite the fixture.
- Re-running with `--force` replaces the fixture.
- Existing normal demo and mock-agent regression tests still pass.
- Path and risk rules are respected.

## Verification

- tests/run-demo.sh
- tests/run-agent-mock.sh
- shellcheck -x bin/palari lib/palari/demo.bash lib/palari/agents_review_scope.bash tests/run-demo.sh tests/run-agent-mock.sh

## Ticket Completion Contract

### Non-Goals

- Do not run opencode, Codex, Claude, or any networked agent.
- Do not make `palari demo` commit, merge, push, accept, or run privileged
  lifecycle actions.
- Do not change real scope-check, CI, report-lint, evidence, or acceptance gate
  behavior.

### Definition Of Done

- A founder/operator can run one command and see a local blocked refusal sample
  in the console.
- Tests cover the new demo path and the existing real mock executor refusal
  path.

### Evidence Required

- Technical report summarizing the fixture, docs, and tests.
- `tests/run-demo.sh` output.
- `tests/run-agent-mock.sh` output.
- Fresh reviewer note.

### Expansion Rules

- Stop if a real external executor, persistent daemon, database, web mutation,
  commit, merge, push, or acceptance action becomes necessary.

### Final Review Gate

- Reviewer checks each done item and recommends accept, reopen, or needs-human.
