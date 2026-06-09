---
id: POS-0027
title: DeepSeek full pilot scaffolds and execution routing
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T14:25:28Z
claim_ref: refs/palari/claims/POS-0027
claim_heartbeat_at: 2026-06-09T14:45:26Z
claim_expires_at: 2026-06-09T14:50:26Z
allowed_paths:
  - research/pilots/deepseek-full-pilot/**
  - research/pilots/deepseek-first-pilot/**
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
  - test -f research/pilots/deepseek-full-pilot/data-capture.md
  - test -d research/pilots/deepseek-full-pilot/runs
  - grep -q 'DSF-DOC-01' research/pilots/deepseek-full-pilot/data-capture.md
  - test -f tickets/open/POS-0028-deepseek-baseline-wave-1.md
  - test -f tickets/open/POS-0029-deepseek-palari-wave-1.md
  - test -f tickets/open/POS-0030-deepseek-baseline-wave-2.md
  - test -f tickets/open/POS-0031-deepseek-palari-wave-2.md
  - test -f tickets/open/POS-0032-deepseek-pilot-fresh-review-and-scoring.md
  - test -f tickets/open/POS-0033-deepseek-pilot-synthesis-and-claims-review.md
target_branch: main
branch: ticket/POS-0027
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0027
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T14:45:43Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0027 DeepSeek full pilot scaffolds and execution routing

## Goal

Create the scaffolding and follow-on routing needed to run the full DeepSeek
pilot defined by POS-0026 without executing any of the 12 model tasks in this
ticket.

## Scope

- Read `research/pilots/deepseek-full-pilot/manifest.md` as the source of
  truth.
- Create `research/pilots/deepseek-full-pilot/data-capture.md` with slots for
  every manifest task:
  - DSF-DOC-01
  - DSF-DOC-02
  - DSF-CLI-01
  - DSF-CLI-02
  - DSF-WEB-01
  - DSF-WEB-02
  - DSF-TST-01
  - DSF-TST-02
  - DSF-GOV-01
  - DSF-GOV-02
  - DSF-EVD-01
  - DSF-EVD-02
- Create the `research/pilots/deepseek-full-pilot/runs/` directory and any
  lightweight placeholder files needed so the intended run-folder layout is
  unambiguous before execution.
- Create the next execution and review tickets from the POS-0026 manifest:
  - POS-0028: run Baseline slots DSF-DOC-02, DSF-CLI-01, and DSF-WEB-02.
  - POS-0029: run Palari-governed slots DSF-DOC-01, DSF-CLI-02, and
    DSF-WEB-01.
  - POS-0030: run Baseline slots DSF-TST-02, DSF-GOV-01, and DSF-EVD-01.
  - POS-0031: run Palari-governed slots DSF-TST-01, DSF-GOV-02, and
    DSF-EVD-02.
  - POS-0032: perform fresh review, scoring, exclusions audit, and data-quality
    check after execution.
  - POS-0033: write the pilot synthesis and claims-boundary review after the
    scored pilot package exists.
- Include exact condition, task IDs, allowed paths, forbidden paths, required
  checks, evidence expectations, and no-overclaim instructions in each
  follow-on ticket.
- Create `reports/POS-0027-technical-report.md`.

## Non-Goals

- Do not execute DeepSeek/opencode model runs.
- Do not implement any product, dashboard, CLI, test, docs, or governance
  changes from the 12 task slots.
- Do not score pilot outcomes before execution.
- Do not publish or draft external claims.
- Do not accept, merge, push, deploy, mutate production, or bypass human
  acceptance.

## Acceptance

- Data-capture scaffolding exists and includes all 12 manifest task IDs.
- The run-folder root exists and makes the intended evidence layout clear.
- POS-0028 through POS-0033 exist with titles, scopes, checks, and claim
  boundaries matching the POS-0026 manifest.
- POS-0027 explains that the actual pilot execution still begins at POS-0028.
- No pilot task has been run in this ticket.
- Technical report explains any deviations from the POS-0026 manifest.

## Verification

- test -f research/pilots/deepseek-full-pilot/data-capture.md
- test -d research/pilots/deepseek-full-pilot/runs
- grep -q 'DSF-DOC-01' research/pilots/deepseek-full-pilot/data-capture.md
- test -f tickets/open/POS-0028-deepseek-baseline-wave-1.md
- test -f tickets/open/POS-0029-deepseek-palari-wave-1.md
- test -f tickets/open/POS-0030-deepseek-baseline-wave-2.md
- test -f tickets/open/POS-0031-deepseek-palari-wave-2.md
- test -f tickets/open/POS-0032-deepseek-pilot-fresh-review-and-scoring.md
- test -f tickets/open/POS-0033-deepseek-pilot-synthesis-and-claims-review.md

## Ticket Completion Contract

### Definition Of Done

- POS-0027 leaves a clean route from the accepted POS-0026 manifest to the
  execution wave.
- A fresh agent can pick up POS-0028 without inventing task assignment, checks,
  prompt structure, or evidence capture rules.

### Evidence Required

- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/runs/`
- POS-0028 through POS-0033 ticket files
- `reports/POS-0027-technical-report.md`
- Palari CI evidence under `reports/evidence/POS-0027/`

### Expansion Rules

- Stop if scaffolding requires secrets, production access, deployment,
  database mutation, destructive git commands, or external publication.
- Stop if a proposed execution ticket changes the POS-0026 randomization,
  condition assignment, task IDs, or claim boundaries without human review.
- Escalate if a worker tries to run model tasks from POS-0027 instead of
  routing them to POS-0028 through POS-0031.

### Final Review Gate

- Reviewer checks that POS-0027 created scaffolding and routing only, preserved
  the POS-0026 manifest, and left actual execution to the follow-on tickets.
