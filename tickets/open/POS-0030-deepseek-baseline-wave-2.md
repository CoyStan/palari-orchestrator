---
id: POS-0030
title: DeepSeek baseline wave 2
status: open
risk: R1
priority: P1
stream: research
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - research/pilots/deepseek-full-pilot/**
  - tickets/open/POS-0030-*.md
  - reports/POS-0030-technical-report.md
  - reports/evidence/POS-0030/**
  - tests/run-roles.sh
  - roles/active/**
  - lib/palari/agents_review_scope.bash
  - tests/run-agent-wrapper.sh
  - reports/**
  - research/evidence-matrix.md
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
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-tst-02/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-gov-01/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-evd-01/prompt.md
  - grep -q 'DSF-TST-02' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-GOV-01' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-EVD-01' research/pilots/deepseek-full-pilot/data-capture.md
target_branch: main
branch: ticket/POS-0030
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0030
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by:
accepted_at:
created: 2026-06-09
updated: 2026-06-09
---

# POS-0030 DeepSeek baseline wave 2

## Goal

Run the second three Baseline-agent DeepSeek slots from the accepted POS-0026
manifest and capture reviewable evidence without using Palari lifecycle context
inside the task prompts.

## Scope

- Run DSF-TST-02: Strengthen role authority lint coverage.
- Run DSF-GOV-01: Make report-lint missing-heading output more actionable.
- Run DSF-EVD-01: Separate local evidence from trusted remote CI in the
  evidence matrix.
- Use DeepSeek `deepseek/deepseek-v4-flash` through opencode.
- Use a fresh agent context per slot.
- Keep Baseline prompts equivalent to their matched Palari-governed prompts
  except that they must not include Palari lifecycle evidence or gate
  instructions.
- Record prompt, command, timestamps, stdout/stderr, exit code, diff, checks,
  timing, review input, scope notes, failed checks, and operator interventions
  in each slot run folder.
- Update `research/pilots/deepseek-full-pilot/data-capture.md`.
- Create `reports/POS-0030-technical-report.md`.

## Slot Checks

- DSF-TST-02:
  - `tests/run-roles.sh`
  - `grep -q 'authority check failed' tests/run-roles.sh`
  - `git diff --check`
- DSF-GOV-01:
  - `tests/run-agent-wrapper.sh`
  - `bash -n bin/palari lib/palari/*.bash`
  - `grep -q 'missing' tests/run-agent-wrapper.sh`
  - `git diff --check`
- DSF-EVD-01:
  - `grep -q 'local evidence is review evidence' research/evidence-matrix.md`
  - `grep -q 'trusted remote CI' research/evidence-matrix.md`
  - `git diff --check`

## Non-Goals

- Do not use Palari lifecycle instructions as part of the Baseline task
  prompts.
- Do not claim safety, speed, performance, or model-quality improvements.
- Do not accept, merge, push, deploy, touch secrets, mutate production, or use
  destructive git commands.
- Do not change POS-0026 assignments.

## Acceptance

- All three baseline slots have run folders with manifest-required evidence.
- Data capture records exact prompts, commands, timings, diffs, checks, and
  confounders for DSF-TST-02, DSF-GOV-01, and DSF-EVD-01.
- Required objective checks are run or marked failed/skipped with reasons.
- A fresh reviewer can score the slots from the evidence without reconstructing
  missing state.

## Verification

- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-tst-02/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-gov-01/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-evd-01/prompt.md
- grep -q 'DSF-TST-02' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-GOV-01' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-EVD-01' research/pilots/deepseek-full-pilot/data-capture.md

## Ticket Completion Contract

### Definition Of Done

- Baseline wave 2 is executed, captured, and review-ready.

### Evidence Required

- Slot run folders for DSF-TST-02, DSF-GOV-01, and DSF-EVD-01
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `reports/POS-0030-technical-report.md`
- Palari CI evidence for POS-0030 as the research-control ticket

### Expansion Rules

- Stop if opencode or DeepSeek cannot run, if the starting state is
  contaminated, or if a slot needs secrets, production access, deployment,
  database mutation, or destructive commands.
- Record exclusions in
  `research/pilots/deepseek-full-pilot/exclusions.md`; do not silently replace
  failed or unflattering runs.

### Final Review Gate

- Reviewer checks that these are Baseline-agent runs, that evidence is complete,
  and that no Palari-governed lifecycle context leaked into the task prompts.
