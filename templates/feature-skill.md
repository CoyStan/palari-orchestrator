---
name: feature-name
description: Preserve a specific feature contract. Use when changing the files, APIs, tests, or user-facing flows owned by this feature.
---

# Feature Name

## When This Applies

Use this when touching the files, APIs, workflows, tests, or review evidence for
this feature.

## Feature Promise

State the user-facing or operator-facing promise this feature must preserve.

## Invariants

- TODO: invariant that future work must not break.
- TODO: source-of-truth or data boundary that must remain true.

## Owned Files And APIs

- TODO: `path/to/file`
- TODO: API, command, or workflow surface.

## Forbidden Behavior

- Do not move product truth, safety boundaries, or acceptance authority into
  this skill.
- Do not add live external writes, secrets, production behavior, or broad
  framework changes unless a ticket explicitly scopes them.

## Required Tests And Browser Paths

- TODO: automated check, manual check, or rendered path required when this
  feature changes.

## Gotchas

- TODO: project-specific trap learned from prior tickets, reviews, or incidents.

## Acceptance Checklist

- The feature promise and invariants still hold.
- Required tests or review paths were run, or a clear not-run reason is
  recorded.
- No forbidden behavior was introduced.
