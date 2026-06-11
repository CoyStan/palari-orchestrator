# GOAL-ID Goal Title

## Why

State why this goal matters and what changes when it is met. One paragraph a
new agent can read and understand without other context.

## Success Criteria

- An observable, checkable outcome a human will use to judge the goal met.
- Another criterion. Avoid vague verbs; prefer "X exists", "Y passes", "Z
  is published".

## Boundaries

List what this goal explicitly does not cover, so agents do not widen scope
in its name.

## Linked Work

Proposals and tickets serving this goal declare `serves_goal: GOAL-ID`.
Create linked tickets with:

```bash
./bin/palari ticket create TICKET-ID "Title" --goal GOAL-ID --allowed PATH --verify COMMAND
```

## Notes

Goals make founder intent machine-readable and traceable. They never grant
authority; roles do that. A human adopts, achieves, or drops a goal.
