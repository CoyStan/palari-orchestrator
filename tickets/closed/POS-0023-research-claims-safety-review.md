---
id: POS-0023
title: Research claims safety review
status: accepted
risk: R2
priority: P2
stream: research
claimed_by: codex
claimed_at: 2026-06-09T12:36:29Z
claim_ref: refs/palari/claims/POS-0023
claim_heartbeat_at: 2026-06-09T12:57:23Z
claim_expires_at: 2026-06-09T13:02:23Z
allowed_paths:
  - research/**
  - docs/**
  - tickets/**
  - reports/**
  - memory/**
forbidden_paths:
  - .env
  - .env.*
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: true
requires_review: true
verification:
  - test -f research/research-claims-review.md
  - grep -q 'Unsupported claims' research/research-claims-review.md
  - grep -q 'Human acceptance' research/research-claims-review.md
  - ./bin/palari role lint
target_branch: main
branch: ticket/POS-0023
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0023
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-SAFETY-REVIEWER
accepted_by: founder
accepted_at: 2026-06-09T12:57:39Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0023 Research claims safety review

## Goal

Create `research/research-claims-review.md`: a safety-review checklist for
claims Palari can responsibly make about AI-agent governance, safety, and
performance after the research artifacts exist.

## Scope

- Define claim tiers: safe to say now, needs pilot evidence, unsupported claims,
  and claims requiring human acceptance before publication.
- Review whether research tickets preserve Palari's authority model.
- Review whether metrics include negative outcomes and failure modes.
- Review whether human acceptance, review gates, and evidence bundles are
  represented accurately.
- Add memory notes only if a reusable governance lesson is found.

## Acceptance

- Unsupported claims are listed clearly.
- Human acceptance is named as the final publication gate.
- The review gives a founder/operator a plain-English "what we can safely say"
  summary.
- The review recommends accept, reopen, or needs-human for the research package.

## Verification

- test -f research/research-claims-review.md
- grep -q 'Unsupported claims' research/research-claims-review.md
- grep -q 'Human acceptance' research/research-claims-review.md
- ./bin/palari role lint

## Ticket Completion Contract

### Non-Goals

- Do not write the public-facing claims page.
- Do not accept the research package by browser action or agent authority.
- Do not weaken role, ticket, evidence, or human acceptance gates.

### Definition Of Done

- The claims review is written, cites the research artifacts it reviewed, and
  separates supported claims from claims that need more evidence.

### Evidence Required

- `research/research-claims-review.md`
- `./bin/palari role lint`
- A reviewer note explaining whether the research package is safe to present.

### Expansion Rules

- Stop if the work requires dashboard, CLI, GitHub, or product-code changes.
- Stop if a claim implies measured performance or safety without study data.
- Stop if acceptance authority is unclear.

### Final Review Gate

- Safety Reviewer checks each claim tier and recommends accept, reopen, or
  needs-human. Founder/human acceptance remains required.
