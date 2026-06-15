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

## Resource And Action Permission Model

The broker evaluates action requests. A request describes who is asking, which
governed work item it belongs to, which tool/action/resource is involved, what
side-effect class it may create, and which authority sources would allow or
forbid it.

The first request schema is:

```yaml
schema_version: broker-action-request-v1
request_id: BRK-REQ-0001
actor: agent-or-human-id
ticket: POS-0070
workflow: WF-0001
risk: R2
tool: filesystem
action: write_file
resource: docs/example.md
side_effect_class: repo_file_write
requires_human: false
requires_policy: false
allowed_by:
  - ticket_scope
  - broker_policy
forbidden_if:
  - resource_outside_ticket_scope
  - forbidden_path
  - credential_required
  - network_required
```

Supported side-effect classes start conservative:

```text
none
local_process_observation
repo_file_read
repo_file_write
external_read
external_write
credential_access
network_access
```

For this version, only mock observation and local sandbox repo-copy execution
are executable. Requests that imply external writes, credential access,
production mutation, or resources outside ticket scope must fail closed until a
later R5-approved broker boundary authorizes and enforces them. Local sandbox
mode scrubs obvious credential environment variables, but it is not a network
isolation boundary.

The first result schema is:

```yaml
schema_version: broker-result-v1
request_id: BRK-REQ-0001
status: allowed|denied|observed|failed
decision_reason: ticket_scope_passed
observed_at: "2026-06-15T00:00:00Z"
input_hash: sha256-of-request
output_hash: sha256-of-result-material
changed_resources:
  - docs/example.md
side_effects_enabled: false
signed_by: broker-mock
```

`allowed` is reserved for a future enforcing broker or sandbox mode. The mock
broker uses `observed` for commands it ran only as local evidence, `denied` for
refusals, and `failed` for command failures. A mock `observed` result is not a
permission grant.

## Broker Observation Schema V1

Every broker run writes a schema-versioned observation summary:

```json
{
  "schema_version": "broker-observation-v1",
  "ticket": "POS-0071",
  "workflow": "WF-0001",
  "run_id": "RUN-20260615T000000Z-1234",
  "broker_mode": "mock",
  "boundary_type": "observed_only",
  "command": ["printf", "hello"],
  "working_directory": "/path/to/repo",
  "started_at": "2026-06-15T00:00:00Z",
  "ended_at": "2026-06-15T00:00:01Z",
  "exit_code": 0,
  "side_effects_enabled": false,
  "credentials_available_to_agents": false,
  "network_or_hosted_api_access": false,
  "changed_paths": [],
  "forbidden_path_changes": [],
  "decision": "observed",
  "decision_reasons": ["mock broker observed command"],
  "input_hash": "sha256",
  "output_hash": "sha256",
  "signed_by": "broker-mock"
}
```

`signed_by: broker-mock` is an explicit mock signature label, not a
cryptographic ForgeGate acceptance and not human approval. Until a later ticket
adds a stronger sandbox or real broker boundary, all observations must use:

```yaml
broker_mode: mock
boundary_type: observed_only
side_effects_enabled: false
credentials_available_to_agents: false
network_or_hosted_api_access: false
```

Local sandbox broker observations use:

```yaml
broker_mode: sandbox
boundary_type: local_sandbox_repo_copy
side_effects_enabled: false
credentials_available_to_agents: false
network_or_hosted_api_access: false
network_isolation_enforced: false
```

Local sandbox mode executes a command in a disposable repo copy, detects changed
paths, compares them to ticket `allowed_paths` and `forbidden_paths`, writes a
patch artifact, and deletes the copy. It never copies changes back to the real
repo. A scoped change records `decision: observed_allowed`. A forbidden or
outside-scope change records `decision: denied_or_violation` and the broker
returns nonzero.

## Evidence Boundary

Mock and local sandbox broker runs write evidence under:

```text
reports/evidence/TICKET-ID/broker/RUN-*/
```

Each run records:

- request and result artifacts
- command and cwd
- exit code
- stdout/stderr artifacts and SHA-256 hashes
- observed changed paths from a cheap git-status diff
- local sandbox patch artifacts when sandbox mode runs
- refusal reason when a command is blocked
- `side_effects_enabled: false`

## Refusals

The mock broker refuses obvious dangerous command patterns before execution.
Refusal evidence is still preserved for review.

Current denial reasons include:

```text
dangerous_command_refused
credential_required
network_required
resource_outside_ticket_scope
forbidden_path
real_side_effect_requested
```

`dangerous_command_refused` is enforced before command execution. Local sandbox
mode also records `sandbox_scope_violation` when changed paths are forbidden or
outside ticket scope. Other reasons remain contract vocabulary for later
permission-check tickets.

## Future Work

Real broker side effects require separate R5 approval, stronger policy gates,
credential isolation, secure-doctor checks, and signed evidence.
