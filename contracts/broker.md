# Broker Contract

The broker is the boundary between agents and side effects.

## Current Mode

BRK-0001 ships mock broker evidence only:

```yaml
real_side_effects_enabled: false
credentials_available_to_agents: false
network_or_hosted_api_access: false
```

`palari broker run` requires `--mock`. No real credentials, hosted APIs,
customer sends, production writes, money movement, or external integrations are
enabled.

## Evidence Boundary

Mock broker runs write evidence under:

```text
reports/evidence/TICKET-ID/broker/RUN-*/
```

Each run records:

- command and cwd
- exit code
- stdout/stderr artifacts and SHA-256 hashes
- observed changed paths from a cheap git-status diff
- refusal reason when a command is blocked
- `side_effects_enabled: false`

## Refusals

The mock broker refuses obvious dangerous command patterns before execution.
Refusal evidence is still preserved for review.

## Future Work

Real broker side effects require separate R5 approval, stronger policy gates,
credential isolation, secure-doctor checks, and signed evidence.
