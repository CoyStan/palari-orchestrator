# POS-0065 Human Report

## Why This Mattered

The secure doctor should be honest about what Palari actually enforces. Before this ticket, it could say R5 required human approval in a way that sounded enforced, even though dual-human R5 acceptance is planned for a later ticket.

## What Changed

- Secure doctor now separates configured controls from enforced controls.
- R5 dual-human approval now shows as configured but not enforced by `palari accept`.
- Policy acceptance, broker side effects, ForgeGate availability, and branch-protection limits are reported as explicit true/false lines.
- The posture stays weak until serious controls are truly enforced.

## What I Should Know

- This does not implement dual-human R5 acceptance. That is the next R5 ticket.
- A weak posture is the correct result here because it avoids overstating safety.

## What To Check

- Path: `lib/palari/init_adopt.bash`
- Command: `./bin/palari doctor secure`

## Recommended Next Move

Fresh-context review POS-0065, then continue to POS-0066 only after acknowledging that POS-0066 is R5 and cannot be self-accepted by an agent.
