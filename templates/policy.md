---
id: POL-EXAMPLE
title: Example simulation policy
status: proposed
mode: simulation
risk_max: R1
conditions:
  - risk<=R1
  - evidence_score>=95
  - scope_check_passed
  - no_open_decisions
created_by:
created: 2026-01-01
updated: 2026-01-01
---

# POL-EXAMPLE Example simulation policy

## Purpose

Describe the repeated low-risk decision this policy simulates.

## Boundary

Describe what this policy must never accept.

## Conditions

List the evidence and ticket-state conditions required.

## Simulation Notes

Record what the simulator showed before any future activation work.
