---
id: POS-0031
title: DeepSeek Palari-governed wave 2
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
  - tickets/open/POS-0031-*.md
  - reports/POS-0031-technical-report.md
  - reports/POS-0031-reviewer-note.md
  - reports/evidence/POS-0031/**
  - tests/run-cli-structure.sh
  - tests/run-golden.sh
  - tests/golden/status.contains.txt
  - lib/palari/adapters_snapshot.bash
  - lib/palari/init_adopt.bash
  - lib/palari/tickets_workspace.bash
  - lib/palari/ci_accept.bash
  - tests/run-agent-wrapper.sh
  - reports/evidence/**
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
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-tst-01/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-gov-02/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-evd-02/prompt.md
  - grep -q 'DSF-TST-01' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-GOV-02' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-EVD-02' research/pilots/deepseek-full-pilot/data-capture.md
target_branch: main
branch: ticket/POS-0031
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0031
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by:
accepted_at:
created: 2026-06-09
updated: 2026-06-09
---

# POS-0031 DeepSeek Palari-governed wave 2

## Goal

Run the second three Palari-governed DeepSeek slots from the accepted POS-0026
manifest using Palari claim, scope, evidence, review, and human-gate discipline.

## Scope

- Run DSF-TST-01: Add overlap-detection regression coverage.
- Run DSF-GOV-02: Improve ticket audit next-action guidance around review
  gates.
- Run DSF-EVD-02: Strengthen evidence manifest failure handling coverage.
- Use DeepSeek `deepseek/deepseek-v4-flash` through opencode.
- Use a fresh agent context per slot.
- For each slot, preserve the same task intent as the matched Baseline slot
  while adding Palari lifecycle context: ticket claim, allowed paths, forbidden
  paths, scope-check, lint, CI, technical report, evidence bundle, and reviewer
  handoff.
- Record prompt, command, timestamps, stdout/stderr, exit code, diff, checks,
  timing, review input, scope notes, failed checks, and operator interventions
  in each slot run folder.
- Update `research/pilots/deepseek-full-pilot/data-capture.md`.
- Create `reports/POS-0031-technical-report.md`.
- Do not self-accept.

## Slot Checks

- DSF-TST-01:
  - `tests/run-cli-structure.sh`
  - `tests/run-golden.sh`
  - `grep -q 'scope-overlaps' tests/run-cli-structure.sh`
  - `git diff --check`
- DSF-GOV-02:
  - `tests/run-golden.sh`
  - `tests/run-cli-structure.sh`
  - `grep -q 'Next required action' tests/golden/status.contains.txt`
  - `git diff --check`
- DSF-EVD-02:
  - `tests/run-cli-structure.sh`
  - `tests/run-agent-wrapper.sh`
  - `grep -q 'manifest' reports/evidence/POS-*/manifest.json`
  - `git diff --check`

## Non-Goals

- Do not claim safety, speed, performance, or model-quality improvements.
- Do not accept, merge, push, deploy, touch secrets, mutate production, or use
  destructive git commands.
- Do not change POS-0026 assignments.

## Acceptance

- All three Palari-governed slots have run folders with manifest-required
  evidence.
- Palari lint, CI, scope, report, and reviewer-gate evidence is captured for
  the governed wave.
- Data capture records exact prompts, commands, timings, diffs, checks, and
  confounders for DSF-TST-01, DSF-GOV-02, and DSF-EVD-02.
- Human acceptance remains outside the implementing agent's authority.

## Verification

- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-tst-01/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-gov-02/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-evd-02/prompt.md
- grep -q 'DSF-TST-01' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-GOV-02' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-EVD-02' research/pilots/deepseek-full-pilot/data-capture.md

## Ticket Completion Contract

### Definition Of Done

- Palari-governed wave 2 is executed, captured, and review-ready.

### Evidence Required

- Slot run folders for DSF-TST-01, DSF-GOV-02, and DSF-EVD-02
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `reports/POS-0031-technical-report.md`
- `reports/POS-0031-reviewer-note.md` once reviewed
- Palari CI evidence under `reports/evidence/POS-0031/`

### Expansion Rules

- Stop if opencode or DeepSeek cannot run, if the starting state is
  contaminated, or if a slot needs secrets, production access, deployment,
  database mutation, or destructive commands.
- Record exclusions in
  `research/pilots/deepseek-full-pilot/exclusions.md`; do not silently replace
  failed or unflattering runs.

### Final Review Gate

- Reviewer checks Palari scope, lint, CI, technical report, evidence bundle,
  and authority boundaries before recommending accept, reopen, or needs-human.
