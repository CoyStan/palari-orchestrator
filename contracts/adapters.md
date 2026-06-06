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
- artifact attestation for `palari-evidence.tgz`

The workflow should call the CLI. It should not reimplement ticket parsing,
scope checks, lifecycle rules, or acceptance policy.

The ruleset JSON is inert until installed in GitHub. Use:

```bash
palari github ruleset-command --repo OWNER/REPO
palari github install-ruleset --repo OWNER/REPO
```

The workflow is a check producer. The ruleset is the merge authority.

## Local Hook Adapter

Local hooks are fast feedback only. They can run `palari lint` and
`palari scope-overlaps`, but they are not an authority boundary because users
can skip hooks.

## Evidence Adapter

CI evidence belongs under `reports/evidence/`. The standard bundle is:

- `verification.log`
- `junit.xml`
- `palari.sarif`

The GitHub adapter packages this directory into `palari-evidence.tgz`, uploads
it as an artifact, and uses `actions/attest` when repository permissions allow
attestations. Human-authored reports remain separate from machine-produced
evidence.

## MCP Adapter

MCP is a delivery protocol for agents. It may expose Palari commands as tools,
but the CLI remains the source of truth and `accept` remains a human or
authorized-reviewer gate.

## Web Adapter

The web adapter is an operator console. It should render `palari snapshot
--json`, then present copyable CLI commands and health signals.

It must not become a separate source of truth:

- no separate ticket database
- no duplicate ticket/report/scope parser
- no acceptance bypass
- no hidden mutation path around `palari`
- no product-specific Palari app assumptions in the portable console

`palari web` binds to `127.0.0.1` by default and runs from the stdlib Python
server in `adapters/web/`.

## Repo-Specific Adapters

Product vocabulary, private app routes, screenshots, founder preferences,
browser scripts, live connectors, and project-specific danger zones belong in
adopters' repositories, not in the portable core.
