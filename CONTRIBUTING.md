# Contributing

Thanks for helping make Palari Orchestrator more trustworthy.

## Development Setup

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git
cd palari-orchestrator
./bin/palari init
tests/run-golden.sh
```

Recommended local tools:

- ShellCheck
- shfmt
- actionlint
- bats-core

## Before Opening A Pull Request

Run:

```bash
tests/run-golden.sh
tests/run-dashboard-rubric.sh
./bin/palari lint
shellcheck bin/palari scripts/palari
shfmt -d bin/palari scripts/palari
actionlint
python3 -m py_compile adapters/web/server.py
bats tests
```

If a tool is not available, say that in the PR.

## Project Boundaries

Keep the core portable: Bash, Markdown, git, and repo files. Put heavier
integrations behind adapters. Do not move product-specific preferences into the
core package.

Security-sensitive changes need tests. In particular, acceptance, evidence,
scope matching, worktree behavior, GitHub governance, and adapter authority
boundaries need negative tests, not just happy paths.
