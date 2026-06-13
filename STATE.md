# Palari Current State

This file is the quick orientation map for collaborators and agents. Read it
before building a feature that might already exist.

Last refreshed: POS-0057, after POS-0056 merged into `origin/main`.

Palari is repo-native governance for AI coding agents. It is not a generic
agent framework, a hosted task runner, or an automatic merge bot. The core
promise is visible, scoped, reviewable work with explicit human gates.

## How To Orient

1. Run `./bin/palari status --next` to see the current gate.
2. Run `./bin/palari state` to print this capability map.
3. Check `CHANGELOG.md` for recent landed tickets.
4. Check the relevant contract under `contracts/` before changing authority,
   scope, lifecycle, signed acceptance, or adapters.
5. Create or claim a scoped ticket before implementation.

## Shipped

### Ticket Governance

- Scoped Markdown tickets with `allowed_paths`, `forbidden_paths`, risk,
  priority, status, verification commands, and required reports.
- Claim leases, heartbeats, review state, reopening, blocking, needs-human
  state, and human/authorized acceptance.
- Scope checks for local and PR-diff paths.
- Ticket audit and queue planning with `palari run --dry-run`.

### Work Isolation

- Ticket branches and worktrees for isolated work.
- Local disposable sandboxes with `sandbox create|list|inspect|destroy`.
- Sandbox docs state clearly that local sandboxes are not a security boundary.
- Sandbox destroy refuses paths without the Palari sandbox marker.

### Executors

- `mock` executor for deterministic demos/tests, including safe and refused
  path scenarios.
- `opencode` executor wiring through the common `agent run` lifecycle.
- `codex` executor wiring and Codex prompt/doctor support.
- `openrouter` text-artifact executor, added in POS-0056.

Executor runs produce evidence under `reports/evidence/TICKET/executor/`.
Evidence records stdout, stderr, exit code, gate results, and resolved model
metadata where available.

### OpenRouter And Model Routing

- Risk-tiered model routing maps tickets to `fast`, `balanced`, or `frontier`
  classes.
- Inspect routing with `palari model routes` and `palari model show TICKET`.
- Tickets can request `model_hint` as a class or exact model.
- `agent run --model` still wins over routing.
- OpenRouter is disabled by default.
- OpenRouter reads the API key from the configured environment variable and
  never stores it in the repository.
- OpenRouter enforces `openrouter_allowed_models` fail-closed.
- OpenRouter tests use dry-run/offline transport and do not require a real key
  or network call.
- Optional `openrouter:advisor` configuration exists for a stronger advisor
  model, but real usage requires human spend/key approval.

### Dashboard And Snapshot

- Optional stdlib web console in `adapters/web/`.
- Dashboard reads `palari snapshot --json` state and shows tickets, roles,
  evidence, reports, progress, next actions, and human gates.
- Executor evidence and scope/CI refusal evidence surface in custody rows.
- Fast stdlib Python snapshot adapter serves `snapshot --json`, `status`, and
  `web --check`, with Bash fallback through full/legacy controls.

### Evidence And Reports

- Standard Palari CI evidence includes `verification.log`, `junit.xml`,
  `palari.sarif`, and `manifest.json`.
- Technical reports and reviewer notes are linted for required headings.
- Evidence quality scoring exists for completeness checks.
- Refused executor work is preserved as evidence instead of erased.

### Signed Acceptance / ForgeGate

- ForgeGate signed acceptance artifacts are imported under `gate/`.
- Signed gates are available as explicit gate commands and contracts.
- Human acceptance remains the authority boundary.

### Plugins, Skills, Roles, Prompts

- Claude plugin packaging is present under `plugin/` and `.claude-plugin/`.
- Agent skills are machine-discoverable and linted.
- Role files and packets support authority visibility and delegation.
- Prompt generation supports next, ticket, and long-run handoffs.

### Research

- DeepSeek pilot artifacts exist under `research/pilots/deepseek-full-pilot/`.
- The pilot measured governance visibility, scope control, reviewability,
  evidence capture, and human acceptance discipline.
- The pilot does not prove safety, speed, productivity, performance, or model
  quality improvements.

## Experimental / Opt-In

- Real OpenRouter execution. Enable only with `openrouter_enabled: true`, an
  approved model allowlist, and a human-provided API key.
- OpenRouter advisor routing. Treat this as spend-sensitive and review the
  request/evidence behavior before use.
- ForgeGate signed acceptance in day-to-day workflows. The kernel exists, but
  teams should decide where it is mandatory.
- Fast snapshot as the default read model. It is intended for operator views;
  full diagnostics still belong to lint, doctor, and full snapshot paths.

## Planned

- A richer collaborator orientation surface that can be regenerated or checked
  against shipped files.
- Stronger stale-worktree and stale-branch recovery guidance.
- More explicit founder/operator inbox decisions in the dashboard.
- More pilot studies comparing old and newer Palari workflows.

## Intentionally Not Supported

- Browser-side accept, merge, push, or deploy buttons.
- Silent acceptance, merge, push, or production mutation by an agent.
- Secret storage in the repository or evidence bundles.
- Treating local sandboxes as a security boundary.
- Claims that Palari has proven safety, speed, productivity, performance, or
  model-quality gains from the current pilot evidence.
- Heavy frontend/package-manager dependencies for the built-in dashboard.

## Before Building Something New

If your idea touches tickets, executors, OpenRouter, dashboard state, evidence,
signed gates, skills, roles, or prompts, first check:

- `STATE.md`
- `CHANGELOG.md`
- `contracts/`
- `./bin/palari status --next`
- `./bin/palari model routes`
- `./bin/palari run --dry-run`

When in doubt, create a small scoped ticket and preserve the decision trail.
