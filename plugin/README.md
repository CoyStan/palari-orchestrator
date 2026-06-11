# Palari Orchestrator Plugin for Claude Code

Repo-native governance for agent-led work, packaged for one-command install.
The plugin gives Claude Code the operating knowledge (skill), workflow entry
points (slash commands), and role-isolated subagents (specialist, fresh
reviewer) for any repository governed by the
[Palari Orchestrator](https://github.com/CoyStan/palari-orchestrator).

## Install

```text
/plugin marketplace add CoyStan/palari-orchestrator
/plugin install palari-orchestrator@palari
```

Then, in any repository:

```text
/palari-orchestrator:adopt          # install the governance layer into this repo
/palari-orchestrator:status         # tickets, goals, decisions, next action
/palari-orchestrator:next           # read-only queue plan, then execute with consent
/palari-orchestrator:ticket ...     # create a well-scoped ticket from a description
/palari-orchestrator:review ID      # fresh-context review via the palari-reviewer agent
/palari-orchestrator:decide ...     # draft a structured decision for the human
```

## What's inside

| Component | Purpose |
| --- | --- |
| `skills/palari-orchestrator` | The operating skill: detect/adopt, full lifecycle, goals, decisions, hard stops. Loads automatically when relevant. |
| `commands/` | Six namespaced slash commands covering adopt, status, plan, ticket, review, decide. |
| `agents/palari-specialist` | Scoped executor for one ticket: worktree, allowed paths, evidence, technical report, never self-accepts. |
| `agents/palari-reviewer` | Fresh-context reviewer: independent judgment, reviewer note, never implements fixes. |

## Authority model

The plugin teaches Claude Code to operate inside Palari's authority
boundaries, not around them. Acceptance (`palari accept`), merging to main,
and recording decisions remain human actions unless the adopted repo's
authority profile explicitly says otherwise. Decision defaults may never
include human-gated actions.

## Codex and other agents

Codex and other AGENTS.md-aware tools get the same governance through the
repository itself: `palari adopt` installs `AGENTS.md` as the operating
contract, which Codex reads natively. Optional Codex prompt files live in
[`adapters/codex/`](../adapters/codex/).
