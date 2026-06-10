"""forgegate: forge-proof accept gates for agent work.

The trusted core is canon.py, keys.py, token.py, attest.py, gate.py.
Everything else (storage, CLI, layouts-as-files) is an adapter around it.
"""
from .keys import Key, verify_signature
from .token import scope, mint, attenuate, verify_chain, leaf
from .attest import create as create_attestation, signature_valid, att_id
from .layout import load as load_layout, validate as validate_layout
from .gate import verify as verify_gate, Verdict

__all__ = [
    "Key", "verify_signature",
    "scope", "mint", "attenuate", "verify_chain", "leaf",
    "create_attestation", "signature_valid", "att_id",
    "load_layout", "validate_layout",
    "verify_gate", "Verdict",
]
__version__ = "0.1.0"
