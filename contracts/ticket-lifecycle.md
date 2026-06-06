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
claimed -> claimed via heartbeat renewal
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

`palari ticket claim` records `claim_ref`, `claim_heartbeat_at`, and
`claim_expires_at`. The default lease is 300 seconds.
Long-running work should renew with:

```bash
palari ticket heartbeat TICKET-ID
```

Expired claims may be reclaimed. Acceptance rejects stale claim leases when a
ticket carries claim metadata.

Acceptance requires:

- acceptance section satisfied or explicitly narrowed
- Ticket Completion Contract satisfied or explicitly narrowed when present
- verification run or a clear not-run reason
- required reports present
- no out-of-scope files changed
- no forbidden paths changed
- required reviewer note present
- explicit named acceptor
