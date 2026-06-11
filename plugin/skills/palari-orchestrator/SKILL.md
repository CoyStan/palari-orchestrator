---
name: palari-orchestrator
description: Use when working in a repository governed by the Palari Orchestrator (a bin/palari executable and palari.config.yaml exist), or when the user asks to adopt Palari governance, create or work scoped tickets, plan the agent queue, run scope checks or CI evidence, perform a fresh-context review, draft a decision for the human, or manage goals. Covers the full lifecycle - goal, proposal, ticket, worktree, packet, scope-check, evidence, review, decision, human acceptance.
---

# Palari Orchestrator Operating Skill

Palari is repo-native governance for agent-led work. The repository is the
source of truth: tickets, goals, decisions, roles, reports, and evidence are
files, and authority only narrows. Humans keep acceptance.

## Detect and adopt

A repo is Palari-governed when `bin/palari` and `palari.config.yaml` exist at
the root. If they do not and the user wants Palari:

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git /tmp/palari-orchestrator
/tmp/palari-orchestrator/bin/palari adopt /path/to/target-repo
cd /path/to/target-repo && ./bin/palari doctor
```

Read the adopted repo's `AGENTS.md` before doing anything else; it is the
operating contract and overrides this skill where they differ.

## The loop

```text
goal -> proposal -> ticket -> worktree -> packet -> scope-check -> evidence -> review -> decision -> accept
```

1. Orient from facts: `git status --short --branch` and `./bin/palari status`.
2. Plan with `./bin/palari run --dry-run` (read-only; `--goal GOAL-ID` to
   focus, `--json` for machine output). Open decisions and human gates are
   stop items; never try to clear them yourself.
3. Work one ticket at a time. Claim it, isolate it, and stay inside scope:

```bash
./bin/palari ticket claim TICKET-ID YOUR-NAME
./bin/palari worktree TICKET-ID
./bin/palari packet TICKET-ID specialist   # read this packet fully; it is your mission
```

4. Edit only inside `allowed_paths`; never touch `forbidden_paths`. Renew
   long work with `./bin/palari ticket heartbeat TICKET-ID`.
5. Produce evidence, then hand off to review:

```bash
./bin/palari ci TICKET-ID --base main
./bin/palari scope-check TICKET-ID
# write reports/TICKET-ID-technical-report.md (use templates/technical-report.md)
./bin/palari ticket ready TICKET-ID
```

6. Review happens with fresh context (see the palari-reviewer agent). The
   reviewer writes `reports/TICKET-ID-reviewer-note.md` and does not fix code.
7. Acceptance is human: `./bin/palari accept TICKET-ID --by NAME` is only run
   by the human or an explicitly authorized reviewer. Never self-accept.

## Goals and decisions

- Link work to intent: `./bin/palari ticket create ID "Title" --goal GOAL-ID ...`.
  List goals with `./bin/palari goal list`; agents may propose goals but only
  humans adopt, achieve, or drop them.
- When work needs human judgment, draft a decision instead of stalling:

```bash
./bin/palari decide create DEC-0001 "Question" \
  --option "Path A (tradeoff)" --option "Path B (tradeoff)" \
  --recommend 1 --default 1 --respond-by YYYY-MM-DD --ticket TICKET-ID
```

  Only a human records the outcome. Defaults may never include accept, merge,
  push, deploy, spend, or credential actions.

## Hard stops

Stop and surface a decision or handoff when work would require: secrets or
credentials, production systems, deploys, database mutation, destructive
commands, paths outside ticket scope, risk above the ticket's tier, or
acceptance authority. `palari accept`, merging to main, and recording
decisions belong to humans unless the repo's authority profile explicitly
says otherwise (`./bin/palari authority check ACTION`).

## Reference

Full contracts live in the adopted repo under `contracts/` (start with
`ticket-lifecycle.md`, `scope-and-paths.md`, `goals-and-decisions.md`).
Templates for every report type are under `templates/`.
