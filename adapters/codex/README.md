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
