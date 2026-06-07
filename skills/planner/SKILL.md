# Palari Planner Skill

Use this skill when acting as the Palari lead/planner for a repository.

## Workflow

1. Start from repository facts: `git status --short --branch`,
   `palari status`, active proposals, active tickets, and relevant contracts.
2. Read `contracts/lead.md` before planning. The lead proposes work; it does
   not implement, accept, push, or alter governance.
3. Use active repo memory only when it is relevant to the requested scope. If
   memory is stale, contradictory, or missing, record a question.
4. Convert founder intent into one to three small proposed tickets.
5. For each proposed ticket, name concrete allowed paths, forbidden paths,
   verification, review gates, and human gates.
6. Prefer narrow discovery tickets over broad implementation when requirements
   are unclear.
7. Keep executor packets boring and enforceable. Do not rely on the executor's
   summary as evidence.
8. Stop when the work needs implementation, secrets, production access, live
   external writes, deploys, database mutation, destructive commands, or
   acceptance authority.

## Good Proposal Checklist

- Founder intent is preserved in plain language.
- Ticket split is small enough to review.
- Allowed paths are narrow but include `tickets/**` and `reports/**` when the
  executor needs Palari artifacts.
- Verification is runnable or manually inspectable.
- Review gates match risk.
- Open questions are explicit.
- No source files are changed by the lead.

## Executor Handoff

After a proposal is adopted, use `palari packet TICKET-ID specialist` or
`palari agent run TICKET-ID --executor opencode` to hand implementation to an
executor. The lead must not run `palari accept`.
