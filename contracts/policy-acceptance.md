# Policy Acceptance Contract

Policy acceptance starts as simulation only.

## Authority Boundary

- Policy commands may explain whether a ticket would satisfy a policy.
- Policy commands must not accept tickets, move tickets, merge, push, deploy,
  write production state, or trigger broker side effects.
- Default policy simulation is limited to `risk_max: R2`.
- R3/R4/R5 work remains human decision work until broker boundaries and R5
  controls mature further.
- R5 tickets are never eligible for policy acceptance.
- A policy with `risk_max: R3`, `risk_max: R4`, or `risk_max: R5` is invalid
  by default.
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

Tickets may carry an `acceptance_mode` field so acceptance intent is explicit.
The allowed values in this version are:

- `human`
- `human_dual`
- `policy_simulation_only`
- `deny`

Only `human` and `human_dual` may close tickets. `policy_simulation_only`
preserves policy evaluation as a read-only signal, and any attempt to accept by
policy must fail with:

```text
policy acceptance is simulation-only in this Palari version
```

## Simulation Rules

`palari policy simulate TICKET-ID` reads ticket, policy, decision, report, and
evidence artifacts and returns `would_accept` or `would_not_accept`.

The simulator is read-only. It must not write to ticket queues or closed
directories.

Supported first-pass conditions:

- `evidence_score>=N`
- `no_open_decisions`
- `scope_check_passed`
- `risk<=R0` through `risk<=R2` for policy suggestions that could become
  candidates in this version

Unknown conditions are preserved in policy artifacts but produce
`would_not_accept` with a clear reason until implemented.

## Candidate Learning Signals

`palari policy candidates` may use repeated low-risk decisions and recorded
outcomes to recommend simulation-only policy candidates. Candidate confidence
may consider:

- similar successful decisions
- human approval rate
- human override rate
- outcome success rate
- rollback, invalidation, or failure rate
- linked outcome evidence

Human overrides and failed, invalidated, or rollback outcomes must reduce
candidate confidence. R3/R4/R5 decisions must not be emitted as policy
candidates by default. Candidate output is advisory and simulation-only; it must
not create policy files, activate policies, accept tickets, or grant authority.

## Future Work

Real policy acceptance requires a separate R5 ticket, stronger evidence, secure
doctor checks, broker boundaries, and explicit human approval of active policy
authority.
