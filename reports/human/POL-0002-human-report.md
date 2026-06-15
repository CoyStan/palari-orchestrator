# POL-0002 Human Report

## Why This Mattered

Policy simulation becomes more useful when Palari can point to repeated
low-risk human decisions that might eventually become safe policy candidates.

## What Changed

POL-0002 adds:

- `palari policy candidates`
- `palari policy candidates --json`

The command suggests simulation policy candidates from repeated decided R0-R2
decisions where the human chose the recommended option.

## What I Should Know

The command is suggestions-only. It does not create policy files, activate
policies, accept tickets, or move lifecycle state. R3/R4/R5 decision classes
are excluded from auto-accept suggestions.

## What To Check

- Repeated R1/R2 decisions produce transparent suggestions.
- R3/R4/R5 decisions are not suggested for auto-acceptance.
- `git status` is unchanged after running candidates.
- No files appear under `policies/` unless a human runs a separate policy
  creation command.

## Founder Acceptance

Founder pre-approval from Quetzali covers this marathon's review path.
POL-0002 is ready for acceptance after green verification and accept-ready
fresh-context review.

## Recommended Next Move

Accept POL-0002 if evidence is clean, then continue to the broker mock evidence
boundary or outcome ledger according to the roadmap.
