---
id: ROLE-ROOT
title: Root Authority
status: active
parent_role:
tier: 0
allowed_paths:
  - "**"
forbidden_paths:
  - .env
  - .env.*
  - "**/secrets/**"
  - "**/*secret*"
  - "**/*token*"
  - infra/prod/**
  - prod/**
max_risk: R4
may_create_roles: true
may_create_tickets: true
may_execute_tickets: false
may_review_tickets: true
may_accept_tickets: true
can_delegate_to:
  - ROLE-ENGINEERING-LEAD
  - ROLE-SPECIALIST
  - ROLE-REVIEWER
must_escalate_when:
  - authority unclear
  - human/founder intent is missing
memory_tags:
  - repo-governance
issued_by: human
accepted_by: founder
accepted_at: 2026-06-07T00:00:00Z
created: 2026-06-07
revoked_by:
revoked_at:
---

# Root Authority

## Responsibility

Owns the top-level repository authority boundary.

## Non-Authority

Does not let agents become authority sources. Tickets, evidence, review, and
acceptance still carry the work lifecycle.
