---
id: POS-0020
title: Safety and performance evidence matrix
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T12:17:39Z
claim_ref: refs/palari/claims/POS-0020
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
  - **/secrets/**
  - **/*secret*
  - **/*token*
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - test -f research/evidence-matrix.md
  - grep -q 'NIST AI RMF' research/evidence-matrix.md
  - grep -q 'OWASP' research/evidence-matrix.md
  - grep -q 'SWE-bench' research/evidence-matrix.md
target_branch: main
branch: ticket/POS-0020
worktree: /home/quetza/palari-orchestrator/../palari-orchestrator-worktrees/POS-0020
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T12:57:39Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0020 Safety and performance evidence matrix

## Goal

Create `research/evidence-matrix.md`: a compact literature and standards map
showing which external evidence supports Palari's safety and performance
research claims, and which claims still need direct measurement.

## Scope

- Summarize evidence anchors from NIST AI RMF, NIST SSDF, OWASP LLM and
  agentic guidance, SWE-bench/SWE-bench Verified, METR long-task research, and
  AI coding-assistant productivity studies.
- Map each external reference to a Palari design control: scoped tickets,
  roles, worktrees, evidence bundles, review packets, CI gates, and human
  acceptance.
- Separate "supported by external guidance" from "must be measured in Palari".
- Include a short source-quality note for each reference.

## Non-Goals

- Do not turn the matrix into marketing copy.
- Do not cite social posts as evidence unless they are clearly labeled as
  market signal rather than research evidence.
- Do not add heavy bibliography tooling.

## Acceptance

- The matrix includes NIST AI RMF, OWASP, and SWE-bench references.
- Each Palari claim is labeled as safety, performance, governance, or market
  signal.
- Each claim has an evidence status: external anchor, Palari-measurable, or
  unsupported.
- Unsupported claims are easy for the Safety Reviewer to find.

## Verification

- test -f research/evidence-matrix.md
- grep -q 'NIST AI RMF' research/evidence-matrix.md
- grep -q 'OWASP' research/evidence-matrix.md
- grep -q 'SWE-bench' research/evidence-matrix.md
