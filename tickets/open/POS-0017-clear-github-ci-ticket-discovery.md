---
id: POS-0017
title: Clear GitHub CI ticket discovery
status: claimed
risk: R1
priority: P2
stream: governance
claimed_by: codex
claimed_at: 2026-06-07T09:53:23Z
claim_ref: refs/palari/claims/POS-0017
claim_heartbeat_at: 2026-06-07T09:53:23Z
claim_expires_at: 2026-06-07T09:58:23Z
allowed_paths:
  - .github/workflows/**
  - adapters/github/workflows/palari.yml
  - bin/palari
  - lib/palari/**
  - tests/**
  - README.md
  - reports/**
  - tickets/**
forbidden_paths:
  - .env
  - .env.*
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - tests/run-github-ci.sh
  - tests/run-golden.sh
  - shellcheck -x bin/palari scripts/palari tests/run-github-ci.sh tests/run-golden.sh
  - shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-github-ci.sh tests/run-golden.sh
target_branch: main
branch: ticket/POS-0017
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0017
accepted_by:
accepted_at:
created: 2026-06-07
updated: 2026-06-07
---

# POS-0017 Clear GitHub CI ticket discovery

## Goal

Move GitHub PR ticket discovery out of workflow YAML and into the Palari CLI so
the merge-gate path is easier to understand, test, and reuse.

## Scope

- Add a `palari github ci` adapter command that discovers ticket IDs from the
  environment, branch name, and changed ticket files.
- Make the installed and template GitHub workflows call that command.
- Keep no-ticket PRs fail-closed, but make the error message explain the
  supported governance and repo-only paths.
- Add regression tests for ticket discovery and the no-ticket message.

## Acceptance

- GitHub workflow ticket extraction is delegated to the CLI.
- No-ticket PRs fail with actionable instructions.
- Explicit repo-only CI remains available for non-merge-gate repository checks.
- Regression tests cover branch, env, changed-ticket, multi-ticket, no-ticket,
  and repo-only cases.

## Verification

- tests/run-github-ci.sh
- tests/run-golden.sh
- shellcheck -x bin/palari scripts/palari tests/run-github-ci.sh tests/run-golden.sh
- shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-github-ci.sh tests/run-golden.sh
