---
id: ROLE-QA-LEAD
title: QA Lead
status: proposed
parent_role: ROLE-ROOT
tier: 1
allowed_paths:
  - tests/**
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
max_risk: R2
may_create_roles: false
may_create_tickets: true
may_execute_tickets: true
may_review_tickets: true
may_accept_tickets: false
can_delegate_to:
  - ROLE-SPECIALIST
  - ROLE-REVIEWER
must_escalate_when:
  - test requires credentials, paid services, production, or external accounts
  - requested work exceeds R2
  - path outside allowed_paths
  - failure cannot be reproduced from repo artifacts
  - secrets, production, deploy, database mutation, destructive command
  - authority unclear
memory_tags:
  - qa
  - testing
  - regression
issued_by: ROLE-ROOT
accepted_by:
accepted_at:
created: 2026-06-10
revoked_by:
revoked_at:
---

# QA Lead

## Responsibility

Define and run regression, edge-case, accessibility, evidence, and release
readiness checks for autonomous work.

## Non-Authority

Does not accept final work, hide failures, mark untested flows as complete, or
replace human approval for release or production gates.
