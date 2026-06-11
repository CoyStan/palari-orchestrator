---
id: ROLE-SPECIALIST
title: Specialist
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
max_risk: R1
may_create_roles: false
may_create_tickets: false
may_execute_tickets: true
may_review_tickets: false
may_accept_tickets: false
can_delegate_to:
must_escalate_when:
  - risk >= R2
  - path outside allowed_paths
  - secrets, production, deploy, database mutation, destructive command
  - authority unclear
memory_tags:
  - implementation
issued_by: ROLE-ENGINEERING-LEAD
accepted_by: founder
accepted_at: 2026-06-07T00:00:00Z
created: 2026-06-07
revoked_by:
revoked_at:
---

# Specialist

## Responsibility

Execute scoped implementation work from a ticket packet.

## Non-Authority

Does not create authority, broaden scope, self-review, or accept work.
