# POS-0039 Technical Report

## Summary

POS-0039 adds proposed operating roles for long-running autonomous
founder/operator workflows. The roles make Product, Design, QA, Release, and
Autonomy Coordinator responsibilities explicit without activating new
authority.

All roles remain `status: proposed` and `may_accept_tickets: false`.

## Changes

- Added `ROLE-PRODUCT-LEAD`.
- Added `ROLE-DESIGN-LEAD`.
- Added `ROLE-QA-LEAD`.
- Added `ROLE-RELEASE-LEAD`.
- Added `ROLE-AUTONOMY-COORDINATOR`.
- Added `docs/autonomy/founder-operator-roles.md`.
- Added `tests/run-autonomy-roles.sh`.
- Tightened POS-0039 ticket scope and completion contract.

## Files Changed

- `roles/proposed/ROLE-PRODUCT-LEAD-product-lead.md`
- `roles/proposed/ROLE-DESIGN-LEAD-design-lead.md`
- `roles/proposed/ROLE-QA-LEAD-qa-lead.md`
- `roles/proposed/ROLE-RELEASE-LEAD-release-lead.md`
- `roles/proposed/ROLE-AUTONOMY-COORDINATOR-autonomy-coordinator.md`
- `docs/autonomy/founder-operator-roles.md`
- `tests/run-autonomy-roles.sh`
- `tickets/open/POS-0039-autonomous-workflow-role-proposals.md`
- `reports/POS-0039-technical-report.md`

## Role Boundaries

- Product Lead: ranks scope, tickets, roadmap slices, and tradeoffs.
- Design Lead: reviews operator-facing UI/UX polish, accessibility, and
  professional feel.
- QA Lead: owns regression, edge-case, accessibility, and evidence checks.
- Release Lead: tracks CI, packaging, release notes, rulesets, and external
  account blockers.
- Autonomy Coordinator: keeps the queue moving through scoped tickets and stops
  at human gates.

All proposed roles preserve secret/production forbidden paths, escalate unclear
authority, and leave acceptance authority with humans.

## Verification

Commands run during implementation:

- `bash -n tests/run-autonomy-roles.sh`
- `tests/run-autonomy-roles.sh`
- `./bin/palari role lint`
- `./bin/palari role list`
- `git diff --check`
- `./bin/palari scope-check POS-0039`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0039/verification.log`
- `reports/evidence/POS-0039/junit.xml`
- `reports/evidence/POS-0039/manifest.json`
- `reports/evidence/POS-0039/palari.sarif`

## Risks / Follow-Ups

- Proposed roles do not affect execution until a human adopts them.
- Adoption should narrow paths for each target repository before activation.
- Future work can connect these roles to prompt generation, queue-runner dry
  runs, and dashboard routing after POS-0037/POS-0038 are accepted.
