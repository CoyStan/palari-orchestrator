# Adoption Contract

Clean adoption means a new repository can install Palari without reading the
source tree or guessing which files matter.

## Success Criteria

An adoption flow is clean when it:

- has one primary command
- refuses unsafe targets
- does not overwrite existing repo files unless `--force` is explicit
- creates the required Palari directories
- preserves existing `AGENTS.md` by writing `AGENTS.palari.md` for manual merge
- prints a post-install health result
- prints the next useful commands
- keeps GitHub rulesets clearly separate from the workflow template
- remains portable Bash, Markdown, and git
- avoids product-specific Palari app preferences

## Required Checks

Every adoption-flow change should run:

```bash
tests/run-adoption.sh
tests/run-golden.sh
tests/run-cli-structure.sh
shellcheck -x bin/palari scripts/palari tests/run-adoption.sh
```

## User Promise

After adoption, this should work in the target repository:

```bash
./bin/palari doctor
./bin/palari status
./bin/palari propose create APP-PROP-0001 "First scoped change" \
  --intent "Describe the change you want."
```

## Non-Goals

- Do not publish an installer package until the repo-native copy flow is stable.
- Do not modify a target repository's product code during adoption.
- Do not install GitHub rulesets automatically without an explicit command.
- Do not turn adoption into a hosted service or hidden state store.
