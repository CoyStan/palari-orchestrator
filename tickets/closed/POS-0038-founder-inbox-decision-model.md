---
id: POS-0038
title: Founder inbox decision model
status: accepted
risk: R2
priority: P1
stream: dashboard
claimed_by: codex
claimed_at: 2026-06-10T21:53:04Z
claim_ref: refs/palari/claims/POS-0038
claim_heartbeat_at: 2026-06-11T05:22:02Z
claim_expires_at: 2026-06-11T05:27:02Z
allowed_paths:
  - lib/palari/dashboard_snapshot.bash
  - lib/palari/adapters_snapshot.bash
  - adapters/web/static/index.html
  - adapters/web/static/app.js
  - adapters/web/static/app-shell.css
  - tests/run-dashboard-rubric.sh
  - tickets/open/POS-0038-*.md
  - tickets/closed/POS-0038-*.md
  - reports/POS-0038-technical-report.md
  - reports/POS-0038-reviewer-note.md
  - reports/evidence/POS-0038/**
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
  - tests/run-dashboard-rubric.sh
  - node --check adapters/web/static/app.js
  - python3 -m py_compile adapters/web/server.py
  - bash -n bin/palari lib/palari/*.bash
  - git diff --check
target_branch: main
branch: ticket/POS-0038
worktree: /home/quetza/palari-orchestrator-worktrees/POS-0038/../palari-orchestrator-worktrees/POS-0038
accepted_by: quetza
accepted_at: 2026-06-11T05:22:04Z
created: 2026-06-10
updated: 2026-06-11
---

# POS-0038 Founder inbox decision model

## Goal

Add a Founder Inbox decision model to the local operator console so founders
and operators can immediately distinguish work that can continue from work that
needs human acceptance, reviewer evidence, or blocker resolution.

## Scope

- Extend `palari snapshot --json` operator data with a read-only inbox array
  derived from existing ticket next actions.
- Render the inbox in the dashboard as a concise decision panel.
- Keep all commands copy-only; do not add browser-side accept, merge, push, or
  lifecycle mutation.
- Update the dashboard rubric to lock the inbox contract.

## Acceptance

- Snapshot JSON includes `operator.inbox` with category, severity, actor,
  ticket id, title, detail, and command fields.
- The dashboard shows a Founder Inbox panel with clear labels for human gates,
  blocked/evidence issues, and work that can continue.
- Empty/loading states remain clear.
- Dashboard tests and snapshot contract checks cover the new surface.
- No new dependencies or build step are added.

## Verification

- tests/run-dashboard-rubric.sh
- node --check adapters/web/static/app.js
- python3 -m py_compile adapters/web/server.py
- bash -n bin/palari lib/palari/*.bash
- git diff --check

## Ticket Completion Contract

### Non-Goals

- Do not implement an autonomous queue runner.
- Do not depend on POS-0037 being accepted.
- Do not add privileged browser actions.
- Do not change acceptance, merge, push, or ForgeGate authority.

### Definition Of Done

- A non-technical operator can open the console and understand the top few
  decisions without reading every ticket file.

### Evidence Required

- POS-0038 technical report.
- Dashboard rubric output.
- Palari CI evidence under `reports/evidence/POS-0038/`.

### Expansion Rules

- Stop if the implementation requires mutating lifecycle state from the
  browser, accepting work, merging, pushing, or adding a process runner.

### Final Review Gate

- Reviewer checks snapshot contract, dashboard clarity, command safety, and
  accessibility before acceptance.
