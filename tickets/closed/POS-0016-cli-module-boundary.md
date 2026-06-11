---
id: POS-0016
title: CLI module boundary
status: accepted
risk: R2
priority: P2
stream: maintainability
claimed_by: founder-closeout
claimed_at: 2026-06-07T09:17:15Z
claim_ref: refs/palari/claims/POS-0016
claim_heartbeat_at: 2026-06-07T09:17:15Z
claim_expires_at: 2026-06-07T13:17:15Z
allowed_paths:
  - bin/palari
  - lib/palari/**
  - tests/**
  - .github/**
  - contracts/**
  - README.md
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-cli-structure.sh
  - tests/run-golden.sh
  - tests/run-adoption.sh
  - shellcheck -x bin/palari scripts/palari tests/run-cli-structure.sh tests/run-adoption.sh tests/run-proposals.sh tests/run-agent-wrapper.sh tests/run-golden.sh tests/run-memory.sh
  - shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-cli-structure.sh
target_branch: main
branch: ticket/POS-0016
worktree:
accepted_by: founder
accepted_at: 2026-06-07T09:25:33Z
created: 2026-06-07
updated: 2026-06-07
---

# POS-0016 CLI module boundary

## Goal

Reduce the maintainability risk from the single large Bash CLI without changing
Palari's portable Bash contract or command behavior.

## Scope

- Keep `bin/palari` as the executable entrypoint, loader, usage text, and
  command dispatcher.
- Move command/helper implementations into named modules under `lib/palari/`.
- Make adoption copy the new module directory.
- Add an executable structure test that defines when the large-CLI risk is
  fixed enough.

## Acceptance

- `bin/palari` stays below 300 lines and contains no `cmd_*` implementations.
- Palari behavior lives in modules under `lib/palari/*.bash`.
- No module exceeds 900 lines.
- Adoption and doctor checks include the module set.
- The existing behavior suite passes.

## Verification

- tests/run-cli-structure.sh
- tests/run-golden.sh
- tests/run-adoption.sh
- shellcheck -x bin/palari scripts/palari tests/run-cli-structure.sh tests/run-adoption.sh tests/run-proposals.sh tests/run-agent-wrapper.sh tests/run-golden.sh tests/run-memory.sh
- shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-cli-structure.sh

## Ticket Completion Contract

### Non-Goals

- Do not rewrite the CLI in another language.
- Do not change command names, command outputs, ticket schema, or acceptance
  semantics.
- Do not refactor the Python adapters.

### Definition Of Done

- `tests/run-cli-structure.sh` encodes the structural criteria.
- CI and static analysis run the structure test and source-aware shell checks.
- Golden/adoption/agent/memory/dashboard flows still pass.

### Evidence Required

- Local verification command list from this ticket.
- Palari CI evidence for `POS-0016`.

### Expansion Rules

- Stop if the change requires semantic edits to lifecycle, scope, evidence, or
  acceptance behavior.

### Final Review Gate

- Reviewer checks that this is a mechanical boundary extraction plus tests, not
  a behavior rewrite.
