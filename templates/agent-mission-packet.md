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
- Acceptor/human: verify evidence, scope, report gates, and authority before
  acceptance.
- Custom review profile: inspect through the named profile lens and produce the
  matching required report when applicable.
- Handoff author: frame options and implications for blocked work; do not
  execute the blocked implementation.
