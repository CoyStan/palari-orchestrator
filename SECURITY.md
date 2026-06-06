# Security Policy

Palari Orchestrator is a governance tool for agent-assisted repository work.
Security reports are welcome, especially around scope bypasses, evidence
forgery, unsafe adapter behavior, and GitHub ruleset enforcement.

## Supported Versions

The project is pre-1.0. Security fixes target `main` until tagged releases are
published.

## Reporting A Vulnerability

Do not open a public issue for a vulnerability that could help bypass Palari
gates. Email the maintainer listed in the repository owner profile, or open a
private GitHub vulnerability report when that feature is enabled.

Please include:

- affected commit or tag
- reproduction steps
- expected versus actual gate behavior
- whether the issue requires local access, GitHub permissions, or a malicious
  pull request

## Scope

In scope:

- `bin/palari` lifecycle, scope, CI, evidence, and acceptance behavior
- GitHub workflow and ruleset templates
- MCP, hook, and web adapters
- tests that should prevent gate bypasses

Out of scope:

- vulnerabilities in downstream repositories that adopt Palari
- social engineering against maintainers
- denial-of-service against local-only dashboard instances without a security
  boundary claim
