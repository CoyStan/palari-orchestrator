# Review And Acceptance Contract

Review is evidence. Acceptance is authority.

Fresh-context reviewers inspect the ticket, changed diff, implementation report,
verification evidence, and only the source/tests needed to validate findings.
They recommend `accept`, `reopen`, or `needs-human`.

Machine evidence should be produced by `palari ci` where possible. The standard
bundle lives under `reports/evidence/TICKET-ID/` and contains:

- `verification.log`
- `junit.xml`
- `palari.sarif`

Specialist reports should cite this bundle in `## CI Evidence` instead of
asking reviewers to trust prose-only verification claims.

In GitHub, the adapter packages evidence as `palari-evidence.tgz`, uploads it as
an artifact, and uses `actions/attest` when permissions allow it. This binds the
evidence bundle to the workflow run instead of treating committed evidence files
as inherently trustworthy.

Custom review profiles are used when a repo wants an extra named lens such as
`product-feel`, `security`, `docs`, or `platform`. These profiles are declared
through `required_reports`; core Palari only enforces that the named report
exists.

`palari accept TICKET-ID --by NAME` is the acceptance gate. It requires:

- ticket status is `in-review`
- the acceptor is named
- ticket lint passes
- report gates pass
- required reviewer, human, and custom reports exist
- non-expired claim lease and claim ref are present when the ticket was claimed

The command records `accepted_by`, records `accepted_at`, moves the ticket to
`tickets/closed/`, and does not merge, push, deploy, or replace human judgment.
