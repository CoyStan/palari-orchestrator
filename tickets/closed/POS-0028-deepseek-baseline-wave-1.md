---
id: POS-0028
title: DeepSeek baseline wave 1
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T15:02:28Z
claim_ref: refs/palari/claims/POS-0028
claim_heartbeat_at: 2026-06-09T15:24:15Z
claim_expires_at: 2026-06-09T16:24:15Z
allowed_paths:
  - research/pilots/deepseek-full-pilot/**
  - tickets/open/POS-0028-*.md
  - tickets/closed/POS-0028-*.md
  - reports/POS-0028-technical-report.md
  - reports/POS-0028-reviewer-note.md
  - reports/evidence/POS-0028/**
  - adapters/mcp/README.md
  - lib/palari/init_adopt.bash
  - lib/palari/tickets_workspace.bash
  - tests/run-cli-structure.sh
  - tests/golden/status.contains.txt
  - adapters/web/static/index.html
  - adapters/web/static/app.js
  - adapters/web/static/styles.css
  - adapters/web/static/app-shell.css
  - adapters/web/README.md
  - tests/run-dashboard-rubric.sh
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
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-doc-02/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-cli-01/prompt.md
  - test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-web-02/prompt.md
  - grep -q 'DSF-DOC-02' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-CLI-01' research/pilots/deepseek-full-pilot/data-capture.md
  - grep -q 'DSF-WEB-02' research/pilots/deepseek-full-pilot/data-capture.md
target_branch: origin/main
branch: ticket/POS-0028-run
worktree: /home/quetza/palari-orchestrator-worktrees/POS-0028-run
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T16:00:38Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0028 DeepSeek baseline wave 1

## Goal

Run the first three Baseline-agent DeepSeek slots from the accepted POS-0026
manifest and capture reviewable evidence without using Palari lifecycle context
inside the task prompts.

## Scope

- Run DSF-DOC-02: Clarify MCP adapter non-mutation boundaries.
- Run DSF-CLI-01: Make stale-claim next-action diagnostics clearer.
- Run DSF-WEB-02: Fix responsive wrapping for long ticket titles and commands.
- Use DeepSeek `deepseek/deepseek-v4-flash` through opencode.
- Use a fresh agent context per slot.
- Keep the Baseline prompts equivalent to their matched Palari-governed prompts
  except that they must not include Palari ticket claim, Palari scope-check,
  Palari CI, Palari evidence-bundle, reviewer-packet, or lifecycle-transition
  instructions.
- Record prompt, command, timestamps, stdout/stderr, exit code, diff, checks,
  timing, review input, scope notes, failed checks, and operator interventions
  in each slot run folder.
- Update `research/pilots/deepseek-full-pilot/data-capture.md`.
- Create `reports/POS-0028-technical-report.md`.

## Slot Checks

- DSF-DOC-02:
  - `grep -q 'does not accept, merge, push, deploy, or bypass human acceptance' adapters/mcp/README.md`
  - `git diff --check`
- DSF-CLI-01:
  - `tests/run-cli-structure.sh`
  - `tests/run-golden.sh`
  - `bash -n bin/palari lib/palari/*.bash`
  - `git diff --check`
- DSF-WEB-02:
  - `tests/run-dashboard-rubric.sh`
  - `node --check adapters/web/static/app.js`
  - `python3 -m py_compile adapters/web/server.py`
  - `git diff --check`
  - screenshot review at 375, 768, and 1280 px

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
  confounders for DSF-DOC-02, DSF-CLI-01, and DSF-WEB-02.
- Required objective checks are run or marked failed/skipped with reasons.
- A fresh reviewer can score the slots from the evidence without reconstructing
  missing state.

## Verification

- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-doc-02/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-cli-01/prompt.md
- test -f research/pilots/deepseek-full-pilot/runs/baseline-dsf-web-02/prompt.md
- grep -q 'DSF-DOC-02' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-CLI-01' research/pilots/deepseek-full-pilot/data-capture.md
- grep -q 'DSF-WEB-02' research/pilots/deepseek-full-pilot/data-capture.md

## Ticket Completion Contract

### Definition Of Done

- Baseline wave 1 is executed, captured, and review-ready.

### Evidence Required

- Slot run folders for DSF-DOC-02, DSF-CLI-01, and DSF-WEB-02
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `reports/POS-0028-technical-report.md`
- Palari CI evidence for POS-0028 as the research-control ticket

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
