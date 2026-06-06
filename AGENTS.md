# Palari Orchestration Agent Template

Use this file as the adopting repository's agent operating contract.

Core spine:

```text
packet-first
git-true
risk-tiered
reviewed-before-accepted
repo-is-law
```

The repository is authoritative for tickets, reports, product docs, and git
state. Chat memory, external notes, and delegated summaries are advisory when
they conflict with repo files.

## Role Authority

- Human/founder: owns product judgment, risk acceptance, and final direction.
  Only the human/founder or an explicitly authorized reviewer may accept work.
- Orchestrator: selects or creates tickets, runs clean/context gates, prepares
  worktrees, emits packets, routes specialists/reviewers, and integrates
  evidence.
- Specialist: executes one bounded ticket inside allowed paths, verifies work,
  writes a technical report, and moves ready work to `in-review`.
- Reviewer: reviews with fresh context. Checks correctness, scope,
  verification, completion contract, and regression risk. Does not implement
  fixes by default.
- Acceptor/human: verifies evidence, review state, scope, and authority before
  accepting. Does not accept missing gates.
- Custom review profile: where configured, reviews through a named lens such as
  security, docs, UI, or platform constraints and writes the matching required
  report.
- Handoff author: frames options when scope, access, authority, or risk blocks
  work. This is a handoff pattern, not a separate core role.

## Ticket Workflow

1. Refresh repository state with `git status --short --branch` and
   `palari status`.
2. Create or select a ticket with risk, allowed paths, forbidden paths,
   verification, review gates, and human gates.
3. Commit accepted ticket setup before creating the worktree.
4. Run `palari worktree TICKET-ID`.
5. Generate packets with `palari packet TICKET-ID specialist` and, when ready,
   `palari packet TICKET-ID reviewer`.
6. Execute only inside ticket scope. Stop on missing authority, forbidden paths,
   higher real risk, secrets, production, live services, deploys, Docker,
   database mutation, destructive commands, or unclear acceptance criteria.
7. Record evidence in reports and run `palari scope-check TICKET-ID`. Use
   `palari ci TICKET-ID --base BASE_REF` so the evidence bundle includes the
   integrity manifest required by `accept`. In GitHub, the required `palari`
   check and evidence attestation provide the trusted merge-path executor.
   `palari ci` fails closed without a ticket; use `--repo-only` only for
   non-merge-gate repository checks.
8. Use `palari scope-overlaps TICKET-ID` before parallel work when write scopes
   may collide. Renew long-running work with `palari ticket heartbeat TICKET-ID`.
9. Move implementation to `in-review`. Acceptance remains a separate human or
   authorized-reviewer gate.

## Integrations

- `palari init --ci` generates the GitHub Actions governance workflow and an
  importable ruleset template. The workflow alone does not protect merges; run
  `palari github install-ruleset --repo OWNER/REPO` to activate required checks.
- `palari init --hooks` generates `lefthook.yml` for fast local feedback. Hooks
  are advisory and can be skipped.
- The GitHub adapter uploads and attests `palari-evidence.tgz` when repository
  permissions allow it.
- `palari mcp manifest` prints optional MCP tool metadata for adapter wrappers.
  It does not expose `accept`; acceptance remains a human or explicitly
  authorized reviewer action.
- `palari web` starts the optional local Palari Console. Use it for monitoring
  and command discovery. It renders `palari snapshot --json`; do not treat it as
  a replacement for ticket files, reports, packets, or `accept`.
- Repo-specific app preferences, browser scripts, screenshots, founder taste,
  and private connectors belong in adapters, not in the Palari core.

## Fast Lane And Governed Lane

Use a compact gate for R0/R1 read/check/coordination or tiny exact edits:

```text
Authority:
Refresh:
Context:
```

Use the governed lane for R2+, visible UI/runtime work, source-of-truth changes,
process authority, broad edits, review-required work, or human-confirmation
work. Governed work needs a ticket, packet, verification, report evidence, and
review before acceptance.

## Closeout

Meaningful closeout should say:

```text
What changed
What did not change
Verification
Changed paths
Risks / follow-ups
Next action
```
