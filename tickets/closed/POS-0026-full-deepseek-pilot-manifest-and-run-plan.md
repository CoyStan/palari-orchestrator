---
id: POS-0026
title: Full DeepSeek pilot manifest and run plan
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T13:58:04Z
claim_ref: refs/palari/claims/POS-0026
claim_heartbeat_at: 2026-06-09T14:24:37Z
claim_expires_at: 2026-06-09T14:29:37Z
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
  - test -f research/pilots/deepseek-full-pilot/manifest.md
  - grep -q '12 completed tasks' research/pilots/deepseek-full-pilot/manifest.md
  - grep -q '6 baseline' research/pilots/deepseek-full-pilot/manifest.md
  - grep -q '6 Palari-governed' research/pilots/deepseek-full-pilot/manifest.md
  - grep -q 'randomization' research/pilots/deepseek-full-pilot/manifest.md
target_branch: main
branch: ticket/POS-0026
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0026
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T14:24:47Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0026 Full DeepSeek pilot manifest and run plan

## Goal

Create the frozen manifest and routing plan for the full DeepSeek pilot before
running more model work. The manifest should turn the accepted research
protocol into a concrete 12-completed-task plan with balanced baseline and
Palari-governed conditions.

## Scope

- Create `research/pilots/deepseek-full-pilot/manifest.md`.
- Select and freeze at least 12 planned completed-task slots: 6 baseline and 6
  Palari-governed.
- Balance task classes across docs, CLI behavior, dashboard polish, tests, and
  governance/reporting using the benchmark suite.
- Define task IDs, condition assignment, objective checks, allowed paths,
  forbidden paths, model choice, run folders, exclusion rules, scoring inputs,
  and reviewer handoff requirements.
- Record whether the pilot uses matched pairs, crossover assignment, or another
  deterministic randomization method.
- Identify which follow-on tickets should run the actual pilot tasks.
- Create `reports/POS-0026-technical-report.md`.
- Do not run the full pilot task set in this ticket.

## Acceptance

- The manifest is specific enough that a fresh agent can run the next pilot
  ticket without inventing task selection or scoring rules.
- The manifest states the minimum first-pilot target as 12 completed tasks, with
  6 baseline and 6 Palari-governed tasks.
- The manifest preserves POS-0025's caution: the study may measure governance
  visibility, scope control, reviewability, evidence capture, and human
  acceptance discipline, but should not claim proven safety or performance
  gains until the pilot data supports it.
- Follow-on execution tickets are identified, but not created unless explicitly
  requested.
- Technical report explains any deviations from
  `research/agent-governance-study-protocol.md` or
  `research/benchmark-task-suite.md`.

## Verification

- test -f research/pilots/deepseek-full-pilot/manifest.md
- grep -q '12 completed tasks' research/pilots/deepseek-full-pilot/manifest.md
- grep -q '6 baseline' research/pilots/deepseek-full-pilot/manifest.md
- grep -q '6 Palari-governed' research/pilots/deepseek-full-pilot/manifest.md
- grep -q 'randomization' research/pilots/deepseek-full-pilot/manifest.md

## Ticket Completion Contract

### Non-Goals

- Do not execute the 12 pilot tasks.
- Do not publish external claims.
- Do not modify product code, dashboard code, adapters, CI, or tests except for
  research/report artifacts needed to define the pilot.
- Do not create broad new research methodology beyond the accepted protocol
  unless a deviation is clearly marked.

### Definition Of Done

- The full-pilot manifest exists, is frozen, and can be used as the source of
  truth for the next execution tickets.
- The next execution-ticket sequence is named clearly enough for a founder or
  operator to route work.

### Evidence Required

- `research/pilots/deepseek-full-pilot/manifest.md`
- `reports/POS-0026-technical-report.md`
- Palari CI evidence under `reports/evidence/POS-0026/`

### Expansion Rules

- Stop if the plan requires secrets, production access, deployment, database
  mutation, or destructive commands.
- Stop if a task cannot be made objectively checkable before execution.
- Escalate if the manifest would support public safety/performance claims
  without completed pilot data and human review.

### Final Review Gate

- Reviewer checks task balance, assignment fairness, objective checks, claim
  boundaries, and follow-on routing before recommending accept, reopen, or
  needs-human.
