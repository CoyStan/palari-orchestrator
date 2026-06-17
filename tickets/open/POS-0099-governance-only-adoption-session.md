---
id: POS-0099
title: Governance-only adoption session
status: open
risk: R4
priority: P1
stream: process
serves_goal: 
model_hint: 
claimed_by:
claimed_at:
claim_ref:
claim_heartbeat_at:
claim_expires_at:
allowed_paths:
  - README.md
  - bin/palari
  - contracts/adoption.md
  - lib/palari/init_adopt.bash
  - plugin/commands/adopt.md
  - skills/adoption/SKILL.md
  - tests/run-adoption.sh
  - reports/POS-0099-*
  - reports/evidence/POS-0099/**
  - tickets/open/POS-0099-*
forbidden_paths:
  - .env
  - .env.*
  - "**/.env"
  - "**/.env.*"
  - "**/secrets/**"
  - "**/*.pem"
  - "**/*.key"
  - "**/*.keystore"
  - "**/*.p12"
  - "**/id_rsa*"
  - "**/id_ed25519*"
  - "**/credentials*"
  - "**/.aws/**"
  - "**/.ssh/**"
  - infra/prod/**
  - prod/**
requires_human_confirmation: true
requires_review: true
verification:
  - bash -n bin/palari lib/palari/init_adopt.bash tests/run-adoption.sh
  - tests/run-adoption.sh
  - tests/run-cli-structure.sh
  - tests/run-readme-assets.sh
  - tests/run-golden.sh
  - "if command -v shellcheck >/dev/null 2>&1; then shellcheck -x bin/palari scripts/palari tests/run-adoption.sh lib/palari/init_adopt.bash; else printf 'shellcheck: unavailable\\n'; fi"
target_branch: main
branch: ticket/POS-0099
worktree: 
accepted_by:
acceptance_mode: human
accepted_at:
created: 2026-06-17
updated: 2026-06-17
---

# POS-0099 Governance-only adoption session

## Goal

Add an explicit governance-only adoption mode so app/product repositories can
start a Palari-governed session without copying the Palari runtime or upstream
orchestrator history into the target repository.

## Scope

- Extend `palari adopt` with a `--governance-only` / `--session-only` mode.
- Keep full adoption behavior unchanged for users who explicitly want local
  `./bin/palari`, CI, hooks, and runtime modules in the target repository.
- Update adopter-facing command/skill/docs guidance so app repos default to
  governance-only scaffolding.
- Add regression coverage proving governance-only adoption does not write
  upstream internals into the target.

## Acceptance

- `palari adopt TARGET --governance-only` creates target-owned governance
  scaffolding, config, and agent-session guidance.
- Governance-only adoption preserves existing `AGENTS.md` by writing
  `AGENTS.palari.md`.
- Governance-only adoption does not copy `bin`, `lib`, `scripts`, `templates`,
  `contracts`, `skills`, `schemas`, `adapters`, `gate`, `layouts`, `examples`,
  `research`, `vendor`, upstream tests, `.claude-plugin`, or POS/COS reports.
- Governance-only adoption refuses `--ci` / `--hooks`, because those require a
  local runtime in the target repository.
- Existing full adoption tests continue to pass.

## Verification

- bash -n bin/palari lib/palari/init_adopt.bash tests/run-adoption.sh
- tests/run-adoption.sh
- tests/run-cli-structure.sh
- tests/run-readme-assets.sh
- tests/run-golden.sh
- if command -v shellcheck >/dev/null 2>&1; then shellcheck -x bin/palari scripts/palari tests/run-adoption.sh lib/palari/init_adopt.bash; else printf 'shellcheck: unavailable\n'; fi

## Ticket Completion Contract

### Non-Goals

- Do not remove or weaken full portable adoption.
- Do not install hosted services, GitHub rulesets, CI, or hooks in
  governance-only mode.
- Do not change product repositories as part of this ticket.

### Definition Of Done

- The CLI, plugin command, adoption skill, README, and adoption contract all
  distinguish governance-only session adoption from full runtime adoption.
- The adoption regression test proves the target repo receives governance
  scaffolding but not upstream Palari internals.
- Ticket CI evidence is passing.

### Evidence Required

- `reports/evidence/POS-0099/verification.log`
- Local dirty-worktree scope-check output for uncommitted review.

### Expansion Rules

- Stop if this begins redesigning the Palari runtime packaging model or
  changing CI/ruleset installation semantics.

### Final Review Gate

- Reviewer checks that app-repo guidance defaults to governance-only adoption
  and that tests block the accidental upstream-runtime copy seen in Radar.
