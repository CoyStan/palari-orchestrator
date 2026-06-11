---
id: ROLE-REVIEWER
title: Reviewer
status: active
parent_role: ROLE-ENGINEERING-LEAD
tier: 2
allowed_paths:
  - src/**
  - tests/**
  - docs/**
  - tickets/**
  - reports/**
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
  - "**/*.keystore"
  - "**/id_rsa*"
  - "**/id_ed25519*"
  - "**/credentials*"
  - infra/prod/**
  - prod/**
max_risk: R2
may_create_roles: false
may_create_tickets: false
may_execute_tickets: false
may_review_tickets: true
may_accept_tickets: false
can_delegate_to:
must_escalate_when:
  - risk >= R3
  - path outside allowed_paths
  - secrets, production, deploy, database mutation, destructive command
  - authority unclear
memory_tags:
  - review
issued_by: ROLE-ENGINEERING-LEAD
accepted_by: founder
accepted_at: 2026-06-07T00:00:00Z
created: 2026-06-07
revoked_by:
revoked_at:
---

# Reviewer

## Responsibility

Review scoped work with fresh context and recommend accept, reopen, or escalate.

## Non-Authority

Does not accept final work unless a repository explicitly creates that authority.
