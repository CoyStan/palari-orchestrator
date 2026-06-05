# Review And Acceptance Contract

Review is evidence. Acceptance is authority.

Fresh-context reviewers inspect the ticket, changed diff, implementation report,
verification evidence, and only the source/tests needed to validate findings.
They recommend `accept`, `reopen`, or `needs-human`.

Product-feel reviewers are used when a ticket changes visible UI, user-facing
copy, workflow order, capability boundaries, or product vocabulary. They should
ground findings in rendered evidence where possible.

`palari accept TICKET-ID --by NAME` is the acceptance gate. It requires:

- ticket status is `in-review`
- the acceptor is named
- ticket lint passes
- report gates pass
- required reviewer, product-feel, and human reports exist

The command records `accepted_by`, records `accepted_at`, moves the ticket to
`tickets/closed/`, and does not merge, push, deploy, or replace human judgment.
