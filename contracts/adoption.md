# Adoption Contract

Clean adoption means a new repository can install Palari without reading the
source tree or guessing which files matter.

## Success Criteria

An adoption flow is clean when it:

- has one primary command
- supports a dry-run preview before writes
- writes a bootstrap/adoption plan artifact before non-dry-run adoption
- refuses non-dry-run adoption until that plan is explicitly approved
- records source path, source ref, target path, imported path manifest,
  excluded paths, and downstream customization boundaries in the plan
- records excluded upstream governance artifacts in the plan, including source
  tickets, reports, evidence bundles, human reports, memory, self-test
  artifacts, humans, workflows, policies, outcomes, goals, and decisions
- refuses unsafe targets
- does not overwrite existing repo files unless `--force` is explicit
- creates the required Palari directories
- leaves downstream governance history directories empty except `.gitkeep`
  scaffolding unless a future explicit import workflow is approved
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

## User Flow

Before writing Palari into the target repository:

```bash
./bin/palari adopt /path/to/repo --dry-run
./bin/palari adopt plan /path/to/repo --out ADOPTION-PLAN.md
# human reviews ADOPTION-PLAN.md, then marks status: approved
./bin/palari adopt /path/to/repo --plan ADOPTION-PLAN.md
cd /path/to/repo
```

After adoption, this should work in the target repository:

```bash
./bin/palari doctor
./bin/palari status
./bin/palari propose create APP-PROP-0001 "First scoped change" \
  --intent "Describe the change you want."
```

Adoption installs the Palari framework substrate. It does not make the source
repo's tickets, reports, evidence bundles, human reports, memory, tests,
humans, workflows, policies, outcomes, goals, or decisions active in the target
repo by default.

## Non-Goals

- Do not publish an installer package until the repo-native copy flow is stable.
- Do not modify a target repository's product code during adoption.
- Do not install GitHub rulesets automatically without an explicit command.
- Do not turn adoption into a hosted service or hidden state store.
