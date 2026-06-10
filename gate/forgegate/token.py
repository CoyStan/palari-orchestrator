"""Delegation tokens.

A token is a chain of signed grants. The root key signs the first grant to a
holder; each holder may sign a further grant to another holder, but only with
a scope that is equal to or narrower than its own (attenuation). Authority can
shrink along the chain, never grow.

Scope fields:
    ticket    exact ticket id, or "*"
    branch    exact branch name, or "*"
    steps     list of step names the holder may attest, or ["*"]
    not_after ISO-8601 UTC instant after which the grant is invalid

Tickets remain pure data everywhere in the system: nothing in a ticket file
can mint, widen, or substitute for a token.

Constraint semantics: at authorization time, every value the work declares in
its context must fnmatch at least one allowed pattern ("src/*" permits
"src/api/handlers.py"; '*' crosses directory separators). During delegation,
narrowing of constraints is checked as a literal subset of patterns, never by
pattern containment: deciding whether one glob implies another is where
escalation bugs live, so the kernel refuses to guess. To delegate finer
patterns, the parent grant must enumerate them explicitly.
"""
import fnmatch
from datetime import datetime, timezone

from .canon import digest
from .keys import Key, verify_signature

WILDCARD = "*"


def _parse_ts(ts: str) -> datetime:
    dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def scope(ticket: str, branch: str, steps, not_after: str, constraints: dict | None = None) -> dict:
    """constraints: optional map of name -> list of allowed values
    (e.g. {"paths": ["src/"], "tools": ["pytest"]}). Narrowing rule: a child
    may only keep or shrink each list, and may not introduce a constraint
    name absent from a parent that has any constraints under that name
    relaxed; concretely, for every name present in the parent, the child's
    list must be a subset, and a child may add new names (adding a
    constraint only restricts further)."""
    s = {
        "ticket": ticket,
        "branch": branch,
        "steps": sorted(set(steps)),
        "not_after": not_after,
    }
    if constraints:
        s["constraints"] = {k: sorted(set(v)) for k, v in constraints.items()}
    return s


def _field_narrows(child: str, parent: str) -> bool:
    return parent == WILDCARD or child == parent


def scope_narrows(child: dict, parent: dict) -> bool:
    """True iff child grants no authority the parent does not hold."""
    if not _field_narrows(child["ticket"], parent["ticket"]):
        return False
    if not _field_narrows(child["branch"], parent["branch"]):
        return False
    if WILDCARD not in parent["steps"]:
        if WILDCARD in child["steps"]:
            return False
        if not set(child["steps"]) <= set(parent["steps"]):
            return False
    if _parse_ts(child["not_after"]) > _parse_ts(parent["not_after"]):
        return False
    # Constraints: for every name the parent constrains, the child must
    # constrain at least as tightly (subset). New names in the child only
    # restrict further, which is always allowed.
    for name, allowed in parent.get("constraints", {}).items():
        child_allowed = child.get("constraints", {}).get(name)
        if child_allowed is None or not set(child_allowed) <= set(allowed):
            return False
    return True


def scope_authorizes(
    s: dict, ticket: str, branch: str, step: str, at: str,
    context: dict | None = None,
    optional_context: set | None = None,
) -> bool:
    """True iff scope s permits attesting `step` on (ticket, branch) at time
    `at`. `context` maps constraint names to the values the work actually
    used (e.g. {"paths": ["src/a.py"]}). Every used value must match an
    allowed pattern, and every constrained dimension must be reported with
    at least one value: a path-constrained token does not authorize work
    that declares no paths (FG-CONSTRAINT-001). A layout may exempt a
    dimension by listing it in `optional_context`; values reported for an
    optional dimension are still checked."""
    if s["ticket"] not in (WILDCARD, ticket):
        return False
    if s["branch"] not in (WILDCARD, branch):
        return False
    if WILDCARD not in s["steps"] and step not in s["steps"]:
        return False
    if _parse_ts(at) > _parse_ts(s["not_after"]):
        return False
    for name, allowed in s.get("constraints", {}).items():
        used = (context or {}).get(name) or []
        if not used and name not in (optional_context or set()):
            return False
        for value in used:
            if not any(fnmatch.fnmatchcase(value, pat) for pat in allowed):
                return False
    return True


def _grant_body(holder_pub: str, scope_: dict, prev_digest: str | None) -> dict:
    return {"v": 1, "holder": holder_pub, "scope": scope_, "prev": prev_digest}


def mint(root: Key, holder_pub: str, scope_: dict) -> list[dict]:
    """Root issues the first grant of a chain."""
    body = _grant_body(holder_pub, scope_, None)
    return [{**body, "sig": root.sign(body)}]


def attenuate(token: list[dict], issuer: Key, new_holder_pub: str, scope_: dict) -> list[dict]:
    """The current holder delegates a narrower scope onward.

    Raises ValueError if the issuer is not the current holder or the new
    scope is not a narrowing of the issuer's scope.
    """
    leaf = token[-1]
    if issuer.public_hex != leaf["holder"]:
        raise ValueError("only the current holder may attenuate this token")
    if not scope_narrows(scope_, leaf["scope"]):
        raise ValueError("attenuation must narrow scope, never widen it")
    body = _grant_body(new_holder_pub, scope_, digest(leaf))
    return token + [{**body, "sig": issuer.sign(body)}]


def verify_chain(token: list[dict], root_pub: str) -> tuple[bool, str]:
    """Walk the chain: signatures, linkage, and monotonic narrowing.

    Returns (ok, reason). On success the leaf holder is token[-1]["holder"]
    and the effective scope is token[-1]["scope"].
    """
    if not token:
        return False, "empty token"
    prev_digest = None
    signer = root_pub
    parent_scope = None
    for i, block in enumerate(token):
        body = {k: block[k] for k in ("v", "holder", "scope", "prev")}
        if block.get("prev") != prev_digest:
            return False, f"block {i}: broken linkage"
        if not verify_signature(signer, body, block.get("sig", "")):
            return False, f"block {i}: invalid signature"
        if parent_scope is not None and not scope_narrows(block["scope"], parent_scope):
            return False, f"block {i}: scope widened during delegation"
        prev_digest = digest(block)
        signer = block["holder"]
        parent_scope = block["scope"]
    return True, "ok"


def leaf(token: list[dict]) -> dict:
    return token[-1]
