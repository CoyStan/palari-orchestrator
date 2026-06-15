# HUM-0001 Human Report

## Why This Mattered

Human Governance Load only becomes useful when Palari can see which human
skills and authority boundaries exist.

## What Changed

HUM-0001 adds proposed/active/revoked human governance profiles and
`palari human create|list|show|lint|adopt|revoke`.

## What I Should Know

Profiles model governance coverage. They do not grant agent authority, create
worker monitoring, or calculate HGL yet.

## What To Check

- Active profiles require roles and skills.
- Skill levels are L1-L5.
- R5 authority requires `may_approve_policy_changes: true`.
- Capacity fields are non-negative integers.

## Recommended Next Move

Accept HUM-0001 after verification, then implement HGL scoring and coverage.
