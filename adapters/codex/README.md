# Palari for Codex (and other AGENTS.md-aware agents)

Codex has no plugin marketplace; its native contract is `AGENTS.md`, which
the Palari Orchestrator already provides. That means Codex support is mostly
free:

1. Adopt Palari into the target repository:

   ```bash
   git clone https://github.com/CoyStan/palari-orchestrator.git /tmp/palari-orchestrator
   /tmp/palari-orchestrator/bin/palari adopt /path/to/your-repo
   ```

2. Codex reads the adopted `AGENTS.md` automatically. It contains the full
   operating contract: lifecycle, roles, goals, decisions, and hard stops.

## Optional: Codex custom prompts

Codex supports user prompt files in `~/.codex/prompts/`, invoked by name.
Install Palari's prompts with:

```bash
./adapters/codex/install.sh
```

This copies `palari-next.md`, `palari-ticket.md`, `palari-review.md`, and
`palari-decide.md` into `~/.codex/prompts/`, giving Codex the same workflow
entry points the Claude Code plugin provides. The prompts only describe
workflows; all authority still lives in the repository's `AGENTS.md`,
tickets, and `bin/palari` gates.

If your Codex version stores prompts elsewhere, pass the directory:
`./adapters/codex/install.sh ~/.codex/custom-prompts`.

## Governed executor

Codex can run as a governed Palari executor with the same lifecycle as every
other executor (worktree, packet, evidence, scope-check, ci):

```bash
palari agent run TICKET-ID --executor codex --dry-run   # plan + command.txt only
palari agent run TICKET-ID --executor codex             # real run, gates after
```

The wrapper invokes `codex exec --cd <worktree> --sandbox workspace-write
--json --output-last-message <evidence>/last-message.txt` with a prompt that
points Codex at the mission packet (verified against codex-cli 0.138.0). The
Codex CLI contract lives in a single shim function
(`executor_codex_run` in `lib/palari/agents_review_scope.bash`); if the CLI
changes, only that shim changes. Evidence lands under
`reports/evidence/TICKET-ID/executor/codex/` (run.jsonl, run.stderr,
run.exit, last-message.txt, command.txt, scope-check.*, ci.*).

Codex's own workspace-write sandbox confines writes to the worktree; Palari
gates decide whether the result is admissible. Gate failure preserves
evidence and never advances ticket state.

## Readiness check

```bash
palari codex doctor
```

Reports AGENTS.md presence, `bin/palari`, config, the codex CLI on PATH
(warning only - dry-run works without it), installed prompts (warning only;
fix with `palari codex install`), and the executor entry point. Exits
non-zero only on hard requirements.
