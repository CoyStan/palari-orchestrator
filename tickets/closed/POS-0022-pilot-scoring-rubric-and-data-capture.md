---
id: POS-0022
title: Pilot scoring rubric and data capture
status: accepted
risk: R1
priority: P2
stream: research
claimed_by: codex
claimed_at: 2026-06-09T12:18:18Z
claim_ref: refs/palari/claims/POS-0022
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
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - test -f research/pilot-scoring-rubric.md
  - test -f research/pilot-data-capture-template.md
  - grep -q 'Out-of-scope edits' research/pilot-scoring-rubric.md
  - grep -q 'Review time' research/pilot-data-capture-template.md
target_branch: main
branch: ticket/POS-0022
worktree:
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T12:58:01Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0022 Pilot scoring rubric and data capture

## Goal

Create `research/pilot-scoring-rubric.md` and
`research/pilot-data-capture-template.md` so the first Palari research pilot can
record safety, performance, and operator-comprehension outcomes consistently.

## Scope

- Define a scoring rubric for safety outcomes, including Out-of-scope edits,
  missing evidence, unauthorized lifecycle actions, stale review state, and
  unsafe escalation handling.
- Define a scoring rubric for performance outcomes, including time to patch,
  Review time, rework cycles, CI failures, and time to accepted ticket.
- Define a data capture template that can be copied for each pilot task.
- Include fields for operator comprehension: can a non-technical operator tell
  status, owner/role, next action, evidence, and acceptance readiness?

## Non-Goals

- Do not build an analytics database.
- Do not add dashboard instrumentation yet.
- Do not create claims that cannot be derived from the captured data.

## Acceptance

- The rubric distinguishes safety improvements from performance improvements.
- The template is usable as plain Markdown.
- The template records review time and next-action clarity.
- The template captures both baseline-agent and Palari-governed runs.

## Verification

- test -f research/pilot-scoring-rubric.md
- test -f research/pilot-data-capture-template.md
- grep -q 'Out-of-scope edits' research/pilot-scoring-rubric.md
- grep -q 'Review time' research/pilot-data-capture-template.md
