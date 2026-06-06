# Adapter Boundary

Palari Orchestrator keeps the reusable core small:

- Bash CLI
- Markdown tickets and reports
- git worktrees and refs
- path scope checks
- role packets
- lifecycle, review, and acceptance gates

Adapters may add ecosystem-specific enforcement or ergonomics, but they must not
become required for the core workflow to run.

## GitHub Adapter

The GitHub adapter may generate:

- `.github/workflows/palari.yml`
- `.github/palari-required-checks.ruleset.json`
- required status-check documentation
- artifact upload steps for Palari evidence
- SARIF upload steps for Palari findings

The workflow should call the CLI. It should not reimplement ticket parsing,
scope checks, lifecycle rules, or acceptance policy.

## Local Hook Adapter

Local hooks are fast feedback only. They can run `palari lint` and
`palari scope-overlaps`, but they are not an authority boundary because users
can skip hooks.

## Evidence Adapter

CI evidence belongs under `reports/evidence/`. The standard bundle is:

- `verification.log`
- `junit.xml`
- `palari.sarif`

Future attestation adapters may sign or verify that bundle, but human-authored
reports remain separate from machine-produced evidence.

## MCP Adapter

MCP is a delivery protocol for agents. It may expose Palari commands as tools,
but the CLI remains the source of truth and `accept` remains a human or
authorized-reviewer gate.

## Repo-Specific Adapters

Product vocabulary, private app routes, screenshots, founder preferences,
browser scripts, live connectors, and project-specific danger zones belong in
adopters' repositories, not in the portable core.
