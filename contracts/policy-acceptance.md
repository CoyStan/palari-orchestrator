# Policy Acceptance Contract

Policy acceptance starts as simulation only.

## Authority Boundary

- Policy commands may explain whether a ticket would satisfy a policy.
- Policy commands must not accept tickets, move tickets, merge, push, deploy,
  write production state, or trigger broker side effects.
- R5 tickets are never eligible for policy acceptance.
- A policy with `risk_max: R5` is invalid.
- Unknown policy conditions fail closed during simulation.

## Artifact Model

Policy artifacts live under:

- `policies/proposed/`
- `policies/active/`
- `policies/revoked/`

The first shipped mode is:

```yaml
mode: simulation
```

No command in this contract activates real policy acceptance.

## Simulation Rules

`palari policy simulate TICKET-ID` reads ticket, policy, decision, report, and
evidence artifacts and returns `would_accept` or `would_not_accept`.

The simulator is read-only. It must not write to ticket queues or closed
directories.

Supported first-pass conditions:

- `evidence_score>=N`
- `no_open_decisions`
- `scope_check_passed`
- `risk<=R0` through `risk<=R5`

Unknown conditions are preserved in policy artifacts but produce
`would_not_accept` with a clear reason until implemented.

## Future Work

Real policy acceptance requires a separate R5 ticket, stronger evidence, secure
doctor checks, broker boundaries, and explicit human approval of active policy
authority.
