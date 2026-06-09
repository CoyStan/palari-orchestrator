---
id: POS-0021
title: Palari benchmark task suite design
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T12:18:02Z
claim_ref: refs/palari/claims/POS-0021
claim_heartbeat_at: 2026-06-09T12:57:23Z
claim_expires_at: 2026-06-09T13:02:23Z
allowed_paths:
  - research/**
  - docs/**
  - tickets/**
  - reports/**
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
  - test -f research/benchmark-task-suite.md
  - grep -q 'Baseline workflow' research/benchmark-task-suite.md
  - grep -q 'Palari-governed workflow' research/benchmark-task-suite.md
  - grep -q 'Task selection rules' research/benchmark-task-suite.md
target_branch: main
branch: ticket/POS-0021
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0021
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T12:57:39Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0021 Palari benchmark task suite design

## Goal

Create `research/benchmark-task-suite.md`: a practical benchmark design for a
small repo-native pilot comparing normal AI coding-agent work with
Palari-governed work.

## Scope

- Define Task selection rules for 10 to 20 realistic repository tasks.
- Include a Baseline workflow and a Palari-governed workflow.
- Define task classes: docs, CLI behavior, dashboard polish, tests, and
  governance/reporting.
- Define inclusion/exclusion rules so tasks are not cherry-picked.
- Define randomization or counterbalancing for a small pilot.
- Define how task completion, review quality, rework, and scope violations are
  recorded.

## Non-Goals

- Do not execute the benchmark.
- Do not create synthetic tasks that only Palari can win.
- Do not include production, secrets, deploy, or destructive operations.

## Acceptance

- The suite can be run by a founder/operator with ordinary repo access.
- The suite makes the non-Palari baseline fair and explicit.
- The task list includes objective pass/fail checks where possible.
- The design includes enough qualitative notes to explain ambiguous outcomes.

## Verification

- test -f research/benchmark-task-suite.md
- grep -q 'Baseline workflow' research/benchmark-task-suite.md
- grep -q 'Palari-governed workflow' research/benchmark-task-suite.md
- grep -q 'Task selection rules' research/benchmark-task-suite.md
