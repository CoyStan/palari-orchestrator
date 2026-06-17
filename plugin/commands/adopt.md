---
description: Adopt Palari governance into the current repository (or a given path)
---

Adopt a Palari governance session into the target repository: $ARGUMENTS (default: the current repository root).

Steps:
1. If `bin/palari` already exists in the target, run `./bin/palari doctor` and report health instead of re-adopting.
2. Otherwise clone https://github.com/CoyStan/palari-orchestrator.git to a temporary directory and run `BIN/palari adopt TARGET --governance-only` from the clone.
3. Do not copy Palari internals into product/app repos. In governance-only mode the target must not gain `bin`, `lib/palari`, `adapters`, `gate`, `research`, upstream tests, vendor data, or POS/COS report history.
4. Run the external status command printed by adoption. It should look like `PALARI_ROOT=TARGET PALARI_LIB_DIR=CLONE/lib/palari CLONE/bin/palari status`.
5. Read the target's `AGENTS.md` plus `AGENTS.palari.md` and summarize for the user: the lifecycle, the authority profile in `palari.config.yaml`, and how to run Palari commands from the external checkout.
6. Suggest creating their first goal with the external command form: `PALARI_ROOT=TARGET PALARI_LIB_DIR=CLONE/lib/palari CLONE/bin/palari goal create GOAL-0001 "..." --success "..."`.

Only use full `palari adopt TARGET` when the user explicitly asks to vendor the local Palari runtime or install CI/hooks in that repository. Do not create tickets, commit, or modify product code during adoption. Adoption only installs governance/session scaffolding unless full adoption was explicit.
