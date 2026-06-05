# Agent Mission Packet

The CLI prints this packet shape with `palari packet TICKET-ID ROLE`.

## Required Fields

- Role
- Ticket
- Authority
- Git context
- Worker cd
- Mission
- Read scope
- Allowed paths
- Forbidden paths
- Verification
- Stop conditions
- Closeout

## Worker Rule

Read the packet, ticket, relevant source/tests/diffs/reports, and concrete
evidence needed for the task. Do not self-orient through broad process docs
unless the packet names a trigger.

## Role Defaults

- Specialist: implement only inside ticket and packet scope; move ready work to
  `in-review`, never `accepted`.
- Reviewer: inspect with fresh context; do not implement fixes unless
  reassigned; recommend accept, reopen, or needs-human.
- Product-feel reviewer: inspect rendered UI/copy/workflow/capability boundary
  evidence when the ticket marks product-feel review as required or useful.
- Mediator: frame options and implications; do not execute blocked work.
