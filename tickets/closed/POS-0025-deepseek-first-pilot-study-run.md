---
id: POS-0025
title: DeepSeek first pilot study run
status: accepted
risk: R2
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T13:22:59Z
claim_ref: refs/palari/claims/POS-0025
claim_heartbeat_at: 2026-06-09T13:40:14Z
claim_expires_at: 2026-06-09T13:45:14Z
allowed_paths:
  - research/**
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
  - test -f research/pilots/deepseek-first-pilot/manifest.md
  - test -f research/pilots/deepseek-first-pilot/results.md
  - test -f research/pilots/deepseek-first-pilot/data-capture.md
  - grep -q 'DeepSeek' research/pilots/deepseek-first-pilot/results.md
  - grep -q 'Baseline-agent' research/pilots/deepseek-first-pilot/data-capture.md
  - grep -q 'Palari-governed' research/pilots/deepseek-first-pilot/data-capture.md
target_branch: main
branch: ticket/POS-0025
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0025
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T13:40:21Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0025 DeepSeek first pilot study run

## Goal

Run the first DeepSeek pilot study attempt using the accepted Palari research
framework. Produce a frozen manifest, data-capture sheet, raw run notes, and a
cautious results summary comparing baseline-agent and Palari-governed runs.

## Scope

- Create `research/pilots/deepseek-first-pilot/manifest.md`.
- Create `research/pilots/deepseek-first-pilot/data-capture.md`.
- Create `research/pilots/deepseek-first-pilot/results.md`.
- Store raw prompts, run logs, command outputs, and scoring notes under
  `research/pilots/deepseek-first-pilot/`.
- Use DeepSeek through opencode when credentials and runtime allow it.
- Use disposable workspaces or ticket worktrees for task execution.
- Keep final claims directional and explicitly limited by sample size.

## Acceptance

- The manifest freezes pilot task IDs, conditions, prompts, checks, and model
  choice before execution.
- Data capture records at least one baseline-agent run and one
  Palari-governed run, or records an explicit blocker if DeepSeek execution is
  unavailable.
- Results identify safety, performance, and operator-comprehension observations
  without claiming proven safety or performance gains.
- Raw artifacts are stored in the pilot folder so a reviewer can inspect what
  happened.
- The ticket report explains any deviation from the 12-task full-pilot target.

## Verification

- test -f research/pilots/deepseek-first-pilot/manifest.md
- test -f research/pilots/deepseek-first-pilot/results.md
- test -f research/pilots/deepseek-first-pilot/data-capture.md
- grep -q 'DeepSeek' research/pilots/deepseek-first-pilot/results.md
- grep -q 'Baseline-agent' research/pilots/deepseek-first-pilot/data-capture.md
- grep -q 'Palari-governed' research/pilots/deepseek-first-pilot/data-capture.md

## Ticket Completion Contract

### Non-Goals

- Do not publish claims externally.
- Do not modify production, secrets, deploy paths, or unrelated code.
- Do not accept the study as proof of safety or performance gains.
- Do not spend unbounded model budget if DeepSeek repeatedly fails.

### Definition Of Done

- Pilot artifacts exist, DeepSeek availability is tested, at least the first
  runnable baseline/Palari comparison is recorded, and limitations are clear.

### Evidence Required

- `research/pilots/deepseek-first-pilot/manifest.md`
- `research/pilots/deepseek-first-pilot/data-capture.md`
- `research/pilots/deepseek-first-pilot/results.md`
- Raw run logs under `research/pilots/deepseek-first-pilot/runs/`
- `reports/POS-0025-technical-report.md`
- Palari CI evidence under `reports/evidence/POS-0025/`

### Expansion Rules

- Stop if execution needs credentials that are not already configured.
- Stop if DeepSeek attempts forbidden paths, destructive commands, or lifecycle
  bypasses.
- Stop if the pilot requires changes outside `research/**`, `tickets/**`, or
  `reports/**`.

### Final Review Gate

- Reviewer checks the manifest, raw logs, scoring, and claim boundary before
  recommending accept, reopen, or needs-human.
