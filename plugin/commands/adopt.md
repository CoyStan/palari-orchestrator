---
description: Adopt Palari governance into the current repository (or a given path)
---

Adopt the Palari Orchestrator into the target repository: $ARGUMENTS (default: the current repository root).

Steps:
1. If `bin/palari` already exists in the target, run `./bin/palari doctor` and report health instead of re-adopting.
2. Otherwise clone https://github.com/CoyStan/palari-orchestrator.git to a temporary directory and run `BIN/palari adopt TARGET` from the clone.
3. Run `./bin/palari doctor` in the target and fix anything it flags.
4. Read the target's `AGENTS.md` and summarize for the user: the lifecycle, the authority profile in `palari.config.yaml`, and the three commands they will use most (`status`, `run --dry-run`, `accept`).
5. Suggest creating their first goal: `./bin/palari goal create GOAL-0001 "..." --success "..."`.

Do not create tickets, commit, or modify their code during adoption. Adoption only installs the governance layer.
