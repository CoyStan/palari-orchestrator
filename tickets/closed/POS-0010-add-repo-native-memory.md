---
id: POS-0010
title: Add repo-native memory
status: accepted
risk: R2
priority: P1
stream: core
claimed_by: founder-closeout
claimed_at: 2026-06-07T09:17:14Z
claim_ref: refs/palari/claims/POS-0010
claim_heartbeat_at: 2026-06-07T09:17:14Z
claim_expires_at: 2026-06-07T13:17:14Z
allowed_paths:
  - adapters/memory/**
  - memory/**
  - bin/palari
  - lib/palari/**
  - README.md
  - AGENTS.md
  - palari.config.yaml
  - schemas/**
  - tests/**
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-memory.sh
  - tests/run-golden.sh
  - shellcheck -x bin/palari scripts/palari tests/run-golden.sh tests/run-memory.sh
  - if command -v shfmt >/dev/null 2>&1; then shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-golden.sh tests/run-memory.sh; else echo "shfmt unavailable in this runner; Static Analysis owns formatting"; fi
  - python3 -m py_compile adapters/memory/memory.py adapters/web/server.py
target_branch: main
branch: ticket/POS-0010
worktree:
accepted_by: founder
accepted_at: 2026-06-07T09:25:29Z
created: 2026-06-06
updated: 2026-06-07
---

# POS-0010 Add repo-native memory

## Goal

Add optional Palari repo-native memory so the orchestrator can curate durable,
path-scoped Markdown knowledge into specialist and reviewer packets.

## Scope

- Add memory CLI support and generated cache handling.
- Add optional `memory/` directory structure and memory docs.
- Add packet and snapshot integration.
- Add focused memory tests and golden coverage.
- Update only portable orchestration docs and config/schema.

## Acceptance

- Memory truth lives in `memory/**/*.md`; `.palari/cache/` remains generated.
- Existing Palari usage still works without a memory directory.
- Packets include relevant active memory and exclude proposed, superseded, or
  rejected memory.
- Snapshot JSON exposes a memory summary for adapters without making the web
  console parse memory directly.
- Tests prove add, lint, index, query, context, graph, promote, duplicate truth
  detection, and packet behavior.

## Verification

- tests/run-memory.sh
- tests/run-golden.sh
- shellcheck -x bin/palari scripts/palari tests/run-golden.sh tests/run-memory.sh
- if command -v shfmt >/dev/null 2>&1; then shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-golden.sh tests/run-memory.sh; else echo "shfmt unavailable in this runner; Static Analysis owns formatting"; fi
- python3 -m py_compile adapters/memory/memory.py adapters/web/server.py

## Ticket Completion Contract

### Non-Goals

- Do not add chatbot memory, vector search, cloud state, package managers, or a
  memory server.
- Do not make specialists browse memory broadly.
- Do not turn memory into a replacement for scope-check, CI, review, or accept.

### Definition Of Done

- The PR contains a governed memory subsystem that is optional, repo-visible,
  deterministic, and covered by local tests.

### Evidence Required

- `tests/run-memory.sh`
- `tests/run-golden.sh`
- Static shell and Python checks listed in verification.

### Expansion Rules

- Stop if implementation requires external services, hidden runtime state, or
  non-stdlib dependencies.
- Stop if any needed path falls outside this ticket's allowed paths.

### Final Review Gate

- Reviewer checks the ticket, memory CLI behavior, packet output, snapshot JSON,
  and test coverage before recommending accept, reopen, or needs-human.
