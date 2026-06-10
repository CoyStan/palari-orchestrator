"""Attestations.

An attestation is a signed record that one step of governed work happened:
which step, on which ticket and branch, consuming which exact bytes
(input hashes), producing which exact bytes (output hashes), bound to which
commit, signed by which key, carrying the token that authorized it.

The signature covers everything except itself, including the token, so an
attestation cannot be re-bound to a different authority after signing.
"""
from datetime import datetime, timezone

from .canon import digest
from .keys import Key, verify_signature


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def create(
    key: Key,
    token: list[dict],
    step: str,
    ticket: str,
    branch: str,
    inputs: dict,
    outputs: dict,
    commit: str,
    ts: str | None = None,
    context: dict | None = None,
) -> dict:
    """Create and sign an attestation.

    inputs / outputs map artifact names to sha256 hex digests.
    context maps constraint names to lists of values the work actually used
    (e.g. {"paths": ["src/a.py"]}); it is signed and checked by the gate.
    """
    body = {
        "v": 1,
        "step": step,
        "ticket": ticket,
        "branch": branch,
        "inputs": dict(sorted(inputs.items())),
        "outputs": dict(sorted(outputs.items())),
        "commit": commit,
        "signer": key.public_hex,
        "ts": ts or _now(),
        "context": {k: sorted(set(v)) for k, v in (context or {}).items()},
        "token": token,
    }
    return {**body, "sig": key.sign(body)}


def body_of(att: dict) -> dict:
    return {k: v for k, v in att.items() if k != "sig"}


def signature_valid(att: dict) -> bool:
    return verify_signature(att.get("signer", ""), body_of(att), att.get("sig", ""))


def att_id(att: dict) -> str:
    """Content address of an attestation."""
    return digest(body_of(att))
