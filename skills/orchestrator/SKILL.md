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
6. Run verification or record a clear not-run reason.
7. Write the required report artifact.
8. Run `palari scope-check TICKET-ID` and `palari lint TICKET-ID`.
9. Move implementation to `in-review`; do not self-accept.
10. Use `palari accept TICKET-ID --by NAME` only when acting as the human or an
    explicitly authorized reviewer.

## Stop Conditions

Stop and ask when scope, access, risk, product direction, acceptance authority,
secrets, production systems, live external writes, deploys, Docker, database
mutation, or destructive commands become necessary without explicit ticket
scope.
