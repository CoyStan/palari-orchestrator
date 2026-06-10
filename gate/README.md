# forgegate

Forge-proof accept gates for agent work.

Agents are untrusted workloads. Governance must come from cryptographic
authority, not from agent behavior, prompts, or detection. The gate does not
ask whether the evidence is complete; it asks who had the authority to create
it.

## What this is

A reference kernel implementing signed, attenuating delegation tokens, signed
attestations, and a layout-verified accept gate. The trusted core is around
500 physical lines across five small modules, readable in one sitting on purpose: the
verifier is the trusted computing base, and small is the product.

```
forgegate/
  canon.py    canonical encoding and hashing (one byte representation of anything)
  keys.py     Ed25519 sign/verify
  token.py    delegation chains: mint, attenuate (narrow-only), verify
  attest.py   signed step records: inputs, outputs, commit, signer, token
  gate.py     the verifier: one pure function, accept or refuse with reasons
  ----------------------------- trusted core ends here -----------------------
  layout.py   layouts as data (YAML/JSON): steps, hash flow, dual control
  store.py    adapters: content-addressed file store, git notes
  cli.py      keygen / mint / attenuate / attest / verify / demo
```

## The guarantee

For every step a layout requires, the gate checks that an attestation exists,
its signature verifies, its token chain verifies to the root key with
monotonically narrowing scope, the signer is the token's holder, the scope
authorized that step on that ticket and branch at signing time, declared hash
flow holds byte-for-byte between steps, dual-control steps were signed by
distinct keys, and everything binds to the exact expected commit.

Consequences, each enforced by a test in `tests/test_kernel.py`:

- An implement-scoped agent cannot forge a passing test step, even with
  perfectly valid hashes.
- Tampering with any signed field invalidates the attestation.
- A stolen token is useless to any key that does not hold it.
- A complete, internally valid evidence chain from a foreign root is refused.
- Delegation can narrow authority, never widen it, and a hand-forged widened
  block is caught by the chain walk.
- Expired tokens grant nothing.
- Tests that ran against different bytes than were implemented are refused.
- Self-review is refused even with a valid review-scoped token.
- Injected instructions in tickets grant nothing: the gate never reads
  tickets, only tokens and attestations. Tickets are pure data.

## Quick start

```bash
python -m unittest discover tests -v   # the adversarial suite
python -m forgegate.cli demo           # honest run accepted, forgery refused
```

Real usage:

```bash
python -m forgegate.cli keygen --out root.key                # once
python -m forgegate.cli keygen --out orch.key                # orchestrator
# constraints and context are first-class in the CLI:
#   mint/attenuate: --constraint "paths=src/*,docs/*"   (repeatable)
#   attest:         --context "paths=src/api/handlers.py"
#   verify:         --verify-time <ISO-8601> --max-age <seconds>
python -m forgegate.cli mint --key root.key \
  --holder $(python -c "from forgegate.keys import Key; print(Key.from_hex(open('orch.key').read()).public_hex)") \
  --ticket T-42 --branch feat/x --steps '*' \
  --not-after 2026-12-31T00:00:00Z --out orch.token.json

# orchestrator delegates narrowed scopes to worker keys (attenuate),
# workers attest steps with hashed artifacts (attest),
# CI runs the gate (verify) and merges only on ACCEPTED.
```

Layout example (`layouts/code-change.yml`):

```yaml
name: code-change
steps:
  - name: implement
  - name: test
    consumes: [implement]
  - name: review
    consumes: [test]
    distinct_from: [implement]
```

## Design laws

1. The kernel answers one question only: is this chain of signatures valid
   against this layout. Every feature that wants to live inside the verifier
   goes in an adapter instead.
2. Tickets are pure data. Nothing in a ticket can mint, widen, or substitute
   for a token.
3. Holder identity is a string field. Today it is a key fingerprint; it can
   become a SPIFFE ID without touching the kernel.
4. Storage is untrusted. The gate verifies whatever evidence it is handed,
   wherever it lived.

## Threat model notes (post external review)

- Timestamps are self-reported by signers, so a leaked-but-expired token
  could be used with a backdated `ts`. Defense in the kernel: pass
  `verify_time` (and optionally `max_age_seconds`) to the gate or
  `--verify-time` / `--max-age` to the CLI; future-dated evidence and
  evidence outside the window are refused. Broker-signed time (phase 3)
  removes the residual window entirely.
- Duplicate attestations for the same step are ambiguity and are refused
  outright; retries must supersede explicitly, not race on ordering.
- The gate fails closed: malformed evidence of any shape produces a refusal
  with reasons, never an exception.
- Scopes carry an extensible `constraints` map (paths, tools, data scopes,
  and so on). At authorization time every value in the attestation's
  `context` must fnmatch an allowed pattern, so `paths=src/*` permits
  `src/api/handlers.py` (note: `*` crosses directory separators). During
  delegation, narrowing is a literal subset of patterns, never pattern
  containment: deciding whether one glob implies another is where escalation
  bugs live, so the kernel refuses to guess; a parent that wants to delegate
  finer patterns enumerates them explicitly. Until the broker exists,
  `context` is self-reported like everything else a worker signs.
- The future-timestamp check tolerates small clock skew (`skew_seconds`,
  default 60); found by end-to-end testing, where same-second evidence was
  refused under a second-precision verify time.
- Constrained dimensions require reported context (FG-CONSTRAINT-001): a
  token constrained to `paths=marketing/*` refuses any attestation that
  omits or empties `context.paths`; omission is not a bypass. A layout step
  may exempt a dimension with `optional_context: [name]`, and values
  reported under an optional dimension are still pattern-checked.
- Backdating policy: `verify_time` alone is not sufficient; an expired token
  can still sign an old timestamp inside its validity window. Always pass
  both `--verify-time` and `--max-age`. Integrations should supply these
  automatically (palari accept must never call verify without them).
- The file store fails closed too: corrupt, non-JSON, or non-dict evidence
  files are skipped and reported (`WARN skipped corrupt evidence file`),
  never raised, and verification proceeds to an honest verdict on what
  remains (FG-STORE-001).
- Workers holding keys means attestations are self-reported within their
  authorized scope. That is the designed limit of phases 1 and 2; the broker
  is what converts "the agent signed this" into "the boundary observed this."

## Roadmap (kernel is phase 1 and 2)

- Phase 3: broker. A boundary proxy that holds keys, observes work, and signs
  attestations itself, removing self-reporting entirely and making any agent
  framework a valid worker. Enables negative attestations and telemetry.
- Then: memoization on signed cache hits, sampled re-execution, adversarial
  layout steps, self-governed changes (kernel modifications pass their own
  gate), outcome-keyed billing hooks.

## Status

Reference implementation. Reviewed-not-audited cryptographic plumbing on a
standard primitive (Ed25519 via `cryptography`). Port the kernel to Rust for
production once the ergonomics settle; the module boundaries are drawn so the
port is mechanical.
