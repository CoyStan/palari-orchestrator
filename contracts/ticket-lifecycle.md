# Ticket Lifecycle Contract

Valid statuses:

```text
open
claimed
blocked
needs-human
in-review
reopened
accepted
```

Allowed transitions:

```text
open -> claimed
claimed -> blocked
claimed -> needs-human
claimed -> in-review
blocked -> open
needs-human -> open
in-review -> reopened
in-review -> accepted
reopened -> claimed
accepted -> reopened only by explicit human/founder direction
```

Implementation agents may move tickets to `in-review`, `blocked`, or
`needs-human`. They must not accept their own substantive work.

Acceptance requires:

- acceptance criteria satisfied or explicitly narrowed
- Ticket Completion Contract satisfied or explicitly narrowed
- verification run or a clear not-run reason
- required reports present
- no out-of-scope files changed
- no forbidden paths changed
- required reviewer note present
- explicit named acceptor
