---
id: POS-0024
title: Research roles authority setup
status: accepted
risk: R2
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T13:06:18Z
claim_ref: refs/palari/claims/POS-0024
claim_heartbeat_at: 2026-06-09T13:09:26Z
claim_expires_at: 2026-06-09T13:14:26Z
allowed_paths:
  - research/**
  - roles/**
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
  - test -f roles/active/ROLE-RESEARCH-LEAD.md
  - test -f roles/active/ROLE-RESEARCH-EVALUATOR.md
  - test -f roles/active/ROLE-SAFETY-REVIEWER.md
  - ./bin/palari role lint
target_branch: main
branch: ticket/POS-0024
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0024
created_by_role: ROLE-ROOT
delegated_to_role: ROLE-RESEARCH-LEAD
accepted_by: founder
accepted_at: 2026-06-09T13:09:59Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0024 Research roles authority setup

## Goal

Record the repo-native packaging and authority setup for the Palari research
evidence program: the research artifacts, Research Lead, Research Evaluator,
Safety Reviewer roles, and Root delegation entries that make those roles
visible to Palari.

## Scope

- Cover the research package under `research/**`.
- Add active research roles under `roles/active/`.
- Update `ROLE-ROOT` delegation so the research roles are explicit authority
  artifacts.
- Keep all research roles unable to accept tickets, merge, deploy, touch
  secrets, or bypass human gates.
- Produce reports and evidence showing the role graph lints cleanly.

## Acceptance

- `ROLE-RESEARCH-LEAD`, `ROLE-RESEARCH-EVALUATOR`, and
  `ROLE-SAFETY-REVIEWER` exist as active roles.
- `ROLE-ROOT` delegates to the research roles explicitly.
- `./bin/palari role lint` passes.
- The ticket explains that these roles are research-governance authority, not
  acceptance or merge authority.
- The ticket scope covers the research-program package as a whole.

## Verification

- test -f roles/active/ROLE-RESEARCH-LEAD.md
- test -f roles/active/ROLE-RESEARCH-EVALUATOR.md
- test -f roles/active/ROLE-SAFETY-REVIEWER.md
- ./bin/palari role lint

## Ticket Completion Contract

### Non-Goals

- Do not replace the detailed ownership from POS-0019 through POS-0023.
- Do not grant accept, merge, deploy, production, database, or secret access.
- Do not weaken existing engineering roles.

### Definition Of Done

- Research roles exist, root delegation is explicit, role lint passes, and the
  full research-program package is covered by Palari evidence.

### Evidence Required

- `./bin/palari role lint`
- `reports/POS-0024-technical-report.md`
- `reports/POS-0024-reviewer-note.md`
- Palari CI evidence under `reports/evidence/POS-0024/`

### Expansion Rules

- Stop if any role needs accept, merge, production, deployment, database, or
  secret authority.
- Stop if a role needs paths outside `research/**`, `roles/**`, `tickets/**`,
  or `reports/**`.

### Final Review Gate

- Reviewer checks role narrowing, root delegation, forbidden paths, and
  capability flags before recommending accept, reopen, or needs-human.
