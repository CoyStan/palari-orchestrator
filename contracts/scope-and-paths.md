# Scope And Path Contract

Every ticket must declare `allowed_paths` and `forbidden_paths`.

Agents may edit only paths listed in `allowed_paths`. If the work needs another
path, stop and rescope before editing.

Forbidden paths win over allowed paths. If a changed path matches both, the
scope check fails.

Recommended default forbidden paths:

```text
.env
.env.*
**/.env
**/.env.*
**/secrets/**
**/*.pem
**/*.key
**/*.keystore
**/*.p12
**/id_rsa*
**/id_ed25519*
**/credentials*
**/.aws/**
**/.ssh/**
infra/prod/**
prod/**
```

Substring globs such as `**/*secret*` or `**/*token*` are intentionally not
recommended: they block legitimate source files (for example
`gate/forgegate/token.py`) while a renamed credentials file evades them.
Path rules are a guardrail, not secret detection; pair them with a content
scanner such as gitleaks in CI.

Run:

```bash
palari scope-check TICKET-ID
```

Scope checks inspect changed, staged, and untracked paths in the current git
worktree.

In CI, run the same gate against a PR diff:

```bash
palari scope-check TICKET-ID --base origin/main
```

`palari ci` fails closed without a ticket ID, `PALARI_TICKET_ID`, or a
`ticket/*` branch. Use `palari ci --repo-only` only for repository checks that
are not serving as a merge-protection scope gate.

When multiple tickets are active, `allowed_paths` also act as a concurrency
control primitive. Use:

```bash
palari scope-overlaps TICKET-ID
```

The check ignores orchestration evidence paths such as `tickets/**`,
`reports/**`, `handoffs/**`, and `.palari/**` by default. Configure
`concurrency_ignored_overlap_paths` and `scope_overlap_policy` in
`palari.config.yaml` for stricter repos.
