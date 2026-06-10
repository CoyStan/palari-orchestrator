"""Ed25519 keys. Thin wrapper so the rest of the kernel never touches
the crypto library directly and the primitive can be swapped in one place.
"""
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)
from cryptography.hazmat.primitives import serialization
from cryptography.exceptions import InvalidSignature

from .canon import canonical_bytes


class Key:
    """A signing keypair."""

    def __init__(self, private: Ed25519PrivateKey):
        self._private = private

    @classmethod
    def generate(cls) -> "Key":
        return cls(Ed25519PrivateKey.generate())

    @classmethod
    def from_hex(cls, hex_seed: str) -> "Key":
        return cls(Ed25519PrivateKey.from_private_bytes(bytes.fromhex(hex_seed)))

    def to_hex(self) -> str:
        raw = self._private.private_bytes(
            serialization.Encoding.Raw,
            serialization.PrivateFormat.Raw,
            serialization.NoEncryption(),
        )
        return raw.hex()

    @property
    def public_hex(self) -> str:
        raw = self._private.public_key().public_bytes(
            serialization.Encoding.Raw, serialization.PublicFormat.Raw
        )
        return raw.hex()

    def sign(self, obj) -> str:
        """Sign an object's canonical encoding. Returns hex signature."""
        return self._private.sign(canonical_bytes(obj)).hex()


def verify_signature(public_hex: str, obj, signature_hex: str) -> bool:
    """Verify a hex signature over an object's canonical encoding."""
    try:
        pub = Ed25519PublicKey.from_public_bytes(bytes.fromhex(public_hex))
        pub.verify(bytes.fromhex(signature_hex), canonical_bytes(obj))
        return True
    except (InvalidSignature, ValueError):
        return False
