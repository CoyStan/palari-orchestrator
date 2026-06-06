# Palari Orchestrator Skill

Use this skill when adopting or operating the Palari Orchestration workflow in a
repository.

## Workflow

1. Start from repository facts: `git status --short --branch`,
   `palari status`, and the active ticket.
2. Confirm role authority. If implementing, use a specialist packet. If
   reviewing, use a reviewer or product-feel reviewer packet.
3. For meaningful edits, run `palari worktree TICKET-ID` before work starts.
4. Read the mission packet, ticket, relevant code/tests/diffs/reports, and
   evidence. Avoid broad process-doc self-orientation unless triggered.
5. Stay inside `allowed_paths`; never touch `forbidden_paths`.
6. Use `palari scope-overlaps TICKET-ID` before parallel implementation when
   active tickets may share write scope.
7. For long-running claimed work, renew the lease with
   `palari ticket heartbeat TICKET-ID`.
8. Run verification or record a clear not-run reason. In CI, use
   `palari ci TICKET-ID --base BASE_REF` so logs, JUnit, and SARIF are captured
   under `reports/evidence/`.
9. Write the required report artifact, including the `CI Evidence` section when
   machine evidence exists.
10. Run `palari scope-check TICKET-ID` and `palari lint TICKET-ID`.
11. Move implementation to `in-review`; do not self-accept.
12. Use `palari accept TICKET-ID --by NAME` only when acting as the human or an
    explicitly authorized reviewer.

## Adapter Rules

- GitHub workflows and rulesets are generated with `palari init --ci`.
- Local hooks are generated with `palari init --hooks` and are advisory only.
- MCP wrappers should use `palari mcp manifest`; the CLI remains authoritative.
- Product-specific behavior belongs in an adopter adapter, not in the portable
  core.

## Stop Conditions

Stop and ask when scope, access, risk, product direction, acceptance authority,
secrets, production systems, live external writes, deploys, Docker, database
mutation, or destructive commands become necessary without explicit ticket
scope.
