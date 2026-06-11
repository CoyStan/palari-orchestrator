---
id: POS-0019
title: Agent governance research protocol
status: accepted
risk: R1
priority: P1
stream: research
claimed_by: codex
claimed_at: 2026-06-09T12:17:25Z
claim_ref: refs/palari/claims/POS-0019
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
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
requires_human_confirmation: false
requires_review: true
verification:
  - test -f research/agent-governance-study-protocol.md
  - grep -q 'Safety metrics' research/agent-governance-study-protocol.md
  - grep -q 'Performance metrics' research/agent-governance-study-protocol.md
target_branch: main
branch: ticket/POS-0019
worktree:
created_by_role: ROLE-RESEARCH-LEAD
delegated_to_role: ROLE-RESEARCH-EVALUATOR
accepted_by: founder
accepted_at: 2026-06-09T12:57:39Z
created: 2026-06-09
updated: 2026-06-09
---

# POS-0019 Agent governance research protocol

## Goal

Create `research/agent-governance-study-protocol.md`: a small, defensible
study protocol for measuring whether Palari-governed agent work improves safety
and preserves or improves delivery performance compared with a normal AI coding
agent workflow.

## Scope

- Define the research question and hypothesis.
- Define baseline workflow versus Palari-governed workflow.
- Define participant/task setup for a small internal pilot.
- Define Safety metrics, Performance metrics, and quality controls.
- Define what data is captured from tickets, reports, evidence, CI, and review.
- Include limitations so the repo does not overclaim from a small study.

## Non-Goals

- Do not run the study.
- Do not create dashboard or CLI implementation.
- Do not claim Palari proves agent safety; frame it as governance evidence.

## Acceptance

- The protocol is understandable to a founder/operator in five minutes.
- The protocol has clear Safety metrics and Performance metrics sections.
- The protocol explains what would count as a positive, neutral, or negative
  result.
- The protocol names the minimum sample size or task count for a first pilot.
- The protocol states that human acceptance remains the final authority.

## Verification

- test -f research/agent-governance-study-protocol.md
- grep -q 'Safety metrics' research/agent-governance-study-protocol.md
- grep -q 'Performance metrics' research/agent-governance-study-protocol.md
