"""Canonical encoding and hashing.

Everything that is signed or content-addressed goes through this module,
so there is exactly one byte-level representation of any object.
"""
import hashlib
import json


def canonical_bytes(obj) -> bytes:
    """Deterministic JSON encoding: sorted keys, no whitespace, UTF-8."""
    return json.dumps(
        obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")


def digest(obj) -> str:
    """SHA-256 hex digest of an object's canonical encoding."""
    return hashlib.sha256(canonical_bytes(obj)).hexdigest()


def digest_bytes(data: bytes) -> str:
    """SHA-256 hex digest of raw bytes (file contents, artifacts)."""
    return hashlib.sha256(data).hexdigest()


def digest_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()
