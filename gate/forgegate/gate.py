"""The gate.

The verifier. A pure function from (attestations, layout, root public key,
expected ticket/branch/commit) to a verdict. No network, no state. It answers
exactly one question: is this chain of signatures valid against this layout.

For every step the layout requires:

  1. exactly one attestation exists (duplicates are ambiguity, refused),
  2. its signature verifies,
  3. its token chain verifies to the root key,
  4. the token's leaf holder is the attestation's signer,
  5. the token's scope authorized this step, on this ticket and branch,
     at the attestation's timestamp, including any constraint context
     (paths, tools, data scopes) the work declared,
  6. declared hash flow holds: each consumed step's outputs appear,
     byte-identical, among this step's inputs,
  7. dual-control constraints hold: distinct_from steps were signed by
     different keys,
  8. every attestation is bound to the expected commit.

Failure mode is always a refusal with reasons, never an exception: malformed
evidence is just another way of not opening the gate (fail closed).

Timestamps: an attestation's `ts` is self-reported by its signer. A holder
of a leaked-but-expired token could backdate `ts` into the validity window.
Two defenses are provided and should be used together until the broker
exists: pass `verify_time` (an ISO-8601 instant, normally now) and the gate
refuses any attestation timestamped further in the future than a small
clock-skew tolerance (skew_seconds, default 60), and refuses any whose
token would require the timestamp to be trusted further back than
`max_age_seconds` before verify_time. Broker-signed time (phase 3) removes
the residual window entirely.
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone

from . import attest as att_mod
from . import token as tok_mod


@dataclass
class Verdict:
    accepted: bool
    reasons: list[str] = field(default_factory=list)

    def __bool__(self) -> bool:
        return self.accepted


def _parse_ts(ts: str) -> datetime:
    dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _check_step(
    spec: dict,
    a: dict,
    by_step: dict,
    root_pub: str,
    ticket: str,
    branch: str,
    commit: str,
    verify_time: str | None,
    max_age_seconds: int | None,
    skew_seconds: int,
    reasons: list[str],
) -> str | None:
    """All per-attestation checks. Returns the signer on success, else None
    after appending reasons. Raises nothing: callers wrap for fail-closed."""
    name = spec["name"]

    if not att_mod.signature_valid(a):
        reasons.append(f"{name}: attestation signature invalid")
        return None

    ok, why = tok_mod.verify_chain(a.get("token", []), root_pub)
    if not ok:
        reasons.append(f"{name}: token rejected ({why})")
        return None

    leaf = tok_mod.leaf(a["token"])
    if leaf["holder"] != a["signer"]:
        reasons.append(f"{name}: signer is not the token holder")
        return None

    if a.get("branch") != branch:
        reasons.append(f"{name}: attestation branch mismatch")
        return None

    ts = a.get("ts", "")
    if verify_time is not None:
        now = _parse_ts(verify_time)
        when = _parse_ts(ts)
        if (when - now).total_seconds() > skew_seconds:
            reasons.append(f"{name}: attestation timestamped in the future")
            return None
        if max_age_seconds is not None and (now - when).total_seconds() > max_age_seconds:
            reasons.append(f"{name}: attestation older than accepted window")
            return None

    optional = set(spec.get("optional_context", []))
    cons = leaf["scope"].get("constraints", {})
    missing = [c for c in cons
               if not (a.get("context", {}) or {}).get(c)
               and c not in optional]
    if missing:
        reasons.append(
            f"{name}: missing required constraint context: {', '.join(missing)}"
        )
        return None
    if not tok_mod.scope_authorizes(
        leaf["scope"], ticket, branch, name, ts, a.get("context", {}),
        optional_context=optional,
    ):
        reasons.append(f"{name}: token scope does not authorize this step")
        return None

    flow_ok = True
    for upstream in spec.get("consumes", []):
        ups = by_step.get(upstream, [])
        up = ups[0] if len(ups) == 1 else None
        if up is None:
            reasons.append(f"{name}: consumes '{upstream}' which is absent or ambiguous")
            flow_ok = False
            continue
        for art, h in up.get("outputs", {}).items():
            if a.get("inputs", {}).get(art) != h:
                reasons.append(
                    f"{name}: input '{art}' does not match output of '{upstream}'"
                )
                flow_ok = False

    if a.get("commit") != commit:
        reasons.append(f"{name}: bound to a different commit")
        flow_ok = False

    return a["signer"] if flow_ok else None


def verify(
    attestations: list[dict],
    layout: dict,
    root_pub: str,
    ticket: str,
    branch: str,
    commit: str,
    verify_time: str | None = None,
    max_age_seconds: int | None = None,
    skew_seconds: int = 60,
) -> Verdict:
    reasons: list[str] = []
    by_step: dict[str, list[dict]] = {}

    for a in attestations:
        try:
            if a.get("ticket") == ticket:
                by_step.setdefault(str(a.get("step", "")), []).append(a)
        except AttributeError:
            reasons.append("malformed evidence: attestation is not a mapping")

    signer_of: dict[str, str] = {}

    for spec in layout["steps"]:
        name = spec["name"]
        candidates = by_step.get(name, [])
        if not candidates:
            reasons.append(f"{name}: required step has no attestation")
            continue
        if len(candidates) > 1:
            reasons.append(
                f"{name}: {len(candidates)} attestations for one step; "
                f"ambiguous evidence is refused"
            )
            continue
        try:
            signer = _check_step(
                spec, candidates[0], by_step, root_pub, ticket, branch,
                commit, verify_time, max_age_seconds, skew_seconds, reasons,
            )
        except Exception:
            reasons.append(f"{name}: malformed evidence")
            signer = None
        if signer is not None:
            signer_of[name] = signer

    for spec in layout["steps"]:
        name = spec["name"]
        if name not in signer_of:
            continue
        for other in spec.get("distinct_from", []):
            if other in signer_of and signer_of[other] == signer_of[name]:
                reasons.append(
                    f"{name}: must be signed by a different key than '{other}'"
                )

    return Verdict(accepted=not reasons, reasons=reasons or ["ok"])
