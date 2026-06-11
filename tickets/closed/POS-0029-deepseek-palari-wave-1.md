---
id: POS-0029
title: DeepSeek Palari-governed wave 1
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T16:05:40Z
claim_ref: refs/palari/claims/POS-0029
claim_heartbeat_at: 2026-06-09T16:05:48Z
claim_expires_at: 2026-06-09T18:05:48Z
allowed_paths:
  - research/pilots/deepseek-full-pilot/**
  - tickets/open/POS-0029-*.md
  - tickets/closed/POS-0029-*.md
  - reports/POS-0029-technical-report.md
  - reports/POS-0029-reviewer-note.md
  - reports/evidence/POS-0029/**
  - adapters/web/README.md
  - lib/palari/agents_review_scope.bash
  - lib/palari/ci_accept.bash
  - tests/run-cli-structure.sh
  - tests/run-agent-wrapper.sh
  - adapters/web/static/index.html
  - adapters/web/static/app.js
  - adapters/web/static/styles.css
  - adapters/web/static/app-shell.css
  - tests/run-dashboard-rubric.sh
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
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-doc-01/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-cli-02/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-web-01/prompt.md
  - grep -q 'DSF-DOC-01' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-CLI-02' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-WEB-01' research/pilots/deepseek-full-pilot/data-capture.md
target_branch: origin/main
branch: ticket/POS-0029-run
worktree:
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T16:25:37Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0029 DeepSeek Palari-governed wave 1

## Goal

Run the first three Palari-governed DeepSeek slots from the accepted POS-0026
manifest using Palari claim, scope, evidence, review, and human-gate discipline.

## Scope

- Run DSF-DOC-01: Clarify console authority boundaries for operators.
- Run DSF-CLI-02: Make outside-scope `scope-check` output easier to act on.
- Run DSF-WEB-01: Improve ticket detail readiness labels and empty states.
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
- Create `reports/POS-0029-technical-report.md`.
- Do not self-accept.

## Slot Checks

- DSF-DOC-01:
  - `grep -q 'read-only proof surface' adapters/web/README.md`
  - `grep -q 'does not accept, merge, push, or mutate critical lifecycle state' adapters/web/README.md`
  - `git diff --check`
- DSF-CLI-02:
  - `tests/run-cli-structure.sh`
  - `tests/run-agent-wrapper.sh`
  - `bash -n bin/palari lib/palari/*.bash`
  - `git diff --check`
- DSF-WEB-01:
  - `tests/run-dashboard-rubric.sh`
  - `node --check adapters/web/static/app.js`
  - `python3 -m py_compile adapters/web/server.py`
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
  confounders for DSF-DOC-01, DSF-CLI-02, and DSF-WEB-01.
- Human acceptance remains outside the implementing agent's authority.

## Verification

- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-doc-01/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-cli-02/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/palari-dsf-web-01/prompt.md
- grep -q 'DSF-DOC-01' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-CLI-02' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-WEB-01' research/pilots/deepseek-full-pilot/data-capture.md

## Ticket Completion Contract

### Definition Of Done

- Palari-governed wave 1 is executed, captured, and review-ready.

### Evidence Required

- Slot run folders for DSF-DOC-01, DSF-CLI-02, and DSF-WEB-01
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `reports/POS-0029-technical-report.md`
- `reports/POS-0029-reviewer-note.md` once reviewed
- Palari CI evidence under `reports/evidence/POS-0029/`

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
