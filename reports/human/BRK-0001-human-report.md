# BRK-0001 Human Report

## Why This Mattered

The Company AI OS roadmap treats the broker as the eventual boundary for
side effects. This ticket makes that boundary visible before enabling any real
external action.

## What Changed

BRK-0001 adds mock broker evidence commands:

- `palari broker run TICKET-ID --mock -- COMMAND [ARGS...]`
- `palari broker evidence TICKET-ID [--json]`
- `palari broker status`

## What I Should Know

The broker remains mock-only. Real side effects, credentials, hosted APIs,
network calls, production writes, customer sends, and policy-authorized actions
are not enabled.

## What To Check

- Mock evidence is easy to inspect.
- Refused commands still leave evidence.
- `broker status` plainly reports `real_side_effects_enabled: false`.
- No credentials or secrets are written to evidence.

## Founder Acceptance

Founder pre-approval from Quetzali covers this marathon's review path. Final
acceptance should happen only after BRK-0001 verification and fresh-context
review are green.

## Recommended Next Move

Accept BRK-0001 if evidence is clean, then continue to outcome records or
snapshot broker counts according to the roadmap.
