# Contract: Signed Acceptance (Forge-Proof Gate)

## Why this contract exists

Agents are untrusted workloads. Before this contract, acceptance integrity
rested on three honor-system mechanisms: an unsigned `manifest.json` whose
sha256 entries any writer could regenerate, `--by NAME` strings compared
case-insensitively, and ticket frontmatter that lint inspects but anyone can
edit. Each of those answers "does the evidence look complete". None of them
answers the question that matters: who had the authority to create it.

The forge-proof gate, vendored from the forgegate kernel at `gate/`, answers
that question with cryptography instead of convention.

## The boundary

When `gate.enabled: true` in `palari.config.yaml`, `palari accept` refuses a
ticket unless the kernel returns ACCEPTED for it. ACCEPTED means, for every
step the layout requires (implement, test, review by default):

1. Exactly one attestation exists. Duplicates are ambiguity and are refused.
2. Its Ed25519 signature verifies.
3. Its delegation token chain verifies to the repository root key, with
   scope narrowing monotonically on every link. Authority can shrink along
   the chain, never grow.
4. The token's leaf holder is the attestation's signer. A stolen token is
   useless to any other key.
5. The scope authorized that step, on that ticket and branch, at the
   attestation's timestamp.
6. Declared hash flow holds byte for byte: the test attestation consumes the
   implement diff, the review attestation consumes the test evidence.
7. Dual control holds: review is signed by a different key than implement
   and test. Renaming an actor changes nothing; only a different private key
   does.
8. Every attestation is bound to the expected commit.
9. Evidence is fresh: verification always passes both `verify_time` and
   `max_age_seconds`, so future-dated and backdated evidence are refused.

Failure mode is always a refusal with reasons, never an exception. If the
gate is enabled but the kernel is unavailable (missing python3 or the
`cryptography` package), acceptance fails closed.

## What the old mechanisms are now

- The `manifest.json` sha256 validation remains as defense in depth against
  accidental corruption. It is not an authority.
- The `same_actor` string comparison remains as a UX guard against honest
  mistakes. It is not a security boundary.
- Markdown roles remain the planning and review ergonomics layer. Per-ticket
  authority that the gate trusts is a token, minted by
  `palari gate setup-ticket`, never frontmatter.

## Tickets are pure data

The gate never reads ticket bodies. Nothing written into a ticket, including
injected instructions aimed at an agent, can mint, widen, or substitute for
a token. Ticket `verification:` commands are still executed by `palari ci`
as work, but acceptance authority never derives from ticket content.

## Commit binding policy

The kernel checks strict equality against an expected commit. The adapter
resolves that commit as: an explicit `--commit` argument, else the tip of the
ticket's declared branch, else HEAD. One tolerance exists: if all stored
attestations bind a single older commit that is an ancestor of the tip and
the only paths changed since are governance bookkeeping (evidence, tickets,
reports, handoffs), the attested commit is accepted. Committing the evidence
trail must not invalidate the evidence; changing the work must.

## Key handling

- Private keys live under `.palari/gate/keys/` and are gitignored. Never
  commit a `.key` file.
- Only the root public key (`.palari/gate/root.pub`) is needed to verify.
- `palari gate init` creates the root and orchestrator keys once.
- `palari gate setup-ticket ID` attenuates the orchestrator token into three
  step-scoped tokens: implementer (implement), ci (test), reviewer (review).
  Tokens expire after `ticket_token_days`.

## Honest path

```bash
./bin/palari gate init                      # once per repository
./bin/palari ticket create T-42 "..." ...   # unchanged lifecycle
./bin/palari ticket claim T-42 implementer
./bin/palari gate setup-ticket T-42
# ... scoped work on the ticket branch, then commit ...
./bin/palari gate attest-implement T-42     # signs the exact diff bytes
./bin/palari ci T-42                        # evidence; auto-attests test
./bin/palari gate attest-review T-42        # fresh reviewer key signs
./bin/palari ticket ready T-42
./bin/palari accept T-42 --by founder       # gate verdict required
```

## Known limits (inherited from the kernel threat model)

- Timestamps are self-reported by signers. The paired
  `verify_time` + `max_age_seconds` defense bounds the backdating window; a
  broker that observes work and signs time itself removes it entirely and is
  the kernel's phase 3.
- Workers hold their own keys in phases 1 and 2, so attestations are
  self-reported within authorized scope. The gate proves who had authority
  and that nothing was tampered with after signing; it does not yet prove
  the work was observed by a boundary.

See `gate/README.md` for the full kernel design laws and threat model notes,
and `docs/integration/INTEGRATION.md` for the complete replacement inventory.
