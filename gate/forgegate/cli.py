"""Command-line interface.

    forgegate keygen --out root.key
    forgegate mint --key root.key --holder <pub> --ticket T-42 \\
        --branch feat/x --steps implement,test --not-after 2026-07-01T00:00:00Z \\
        --out token.json
    forgegate attenuate --token token.json --key holder.key --holder <pub> \\
        --steps test --not-after ... --out narrower.json
    forgegate attest --key k.key --token t.json --step test --ticket T-42 \\
        --branch feat/x --commit <sha> --input name=path --output name=path
    forgegate verify --layout layout.yml --root <rootpub> --ticket T-42 \\
        --branch feat/x --commit <sha>
    forgegate demo
"""
import json
import sys

import click

from . import attest as att_mod
from . import gate as gate_mod
from . import layout as layout_mod
from . import token as tok_mod
from .canon import digest_file
from .keys import Key
from .store import FileStore


def _load_key(path: str) -> Key:
    with open(path, encoding="utf-8") as f:
        return Key.from_hex(f.read().strip())


def _load_json(path: str):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _dump_json(obj, path: str):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, sort_keys=True)


def _kv_lists(pairs) -> dict:
    """Parse repeatable name=v1,v2 options into {name: [v1, v2]}."""
    out = {}
    for p in pairs:
        name, vals = p.split("=", 1)
        out.setdefault(name, []).extend(v for v in vals.split(",") if v)
    return out


def _artifacts(pairs) -> dict:
    out = {}
    for p in pairs:
        name, path = p.split("=", 1)
        out[name] = digest_file(path)
    return out


@click.group()
def cli():
    """forgegate: forge-proof accept gates for agent work."""


@cli.command()
@click.option("--out", required=True)
def keygen(out):
    key = Key.generate()
    with open(out, "w", encoding="utf-8") as f:
        f.write(key.to_hex())
    click.echo(f"public: {key.public_hex}")


@cli.command()
@click.option("--key", "key_path", required=True, help="root private key file")
@click.option("--holder", required=True, help="holder public key (hex)")
@click.option("--ticket", required=True)
@click.option("--branch", required=True)
@click.option("--steps", required=True, help="comma-separated step names")
@click.option("--not-after", "not_after", required=True, help="ISO-8601 UTC")
@click.option("--constraint", "constraints", multiple=True,
              help="name=v1,v2 (e.g. paths=src/*,docs/*), repeatable")
@click.option("--out", required=True)
def mint(key_path, holder, ticket, branch, steps, not_after, constraints, out):
    root = _load_key(key_path)
    sc = tok_mod.scope(ticket, branch, steps.split(","), not_after,
                       constraints=_kv_lists(constraints) or None)
    _dump_json(tok_mod.mint(root, holder, sc), out)
    click.echo(f"minted -> {out}")


@cli.command()
@click.option("--token", "token_path", required=True)
@click.option("--key", "key_path", required=True, help="current holder's key")
@click.option("--holder", required=True, help="new holder public key (hex)")
@click.option("--ticket", default=None)
@click.option("--branch", default=None)
@click.option("--steps", required=True)
@click.option("--not-after", "not_after", required=True)
@click.option("--constraint", "constraints", multiple=True,
              help="name=v1,v2; defaults to the parent's constraints")
@click.option("--out", required=True)
def attenuate(token_path, key_path, holder, ticket, branch, steps, not_after,
              constraints, out):
    token = _load_json(token_path)
    issuer = _load_key(key_path)
    parent = tok_mod.leaf(token)["scope"]
    cons = _kv_lists(constraints) or parent.get("constraints") or None
    sc = tok_mod.scope(
        ticket or parent["ticket"],
        branch or parent["branch"],
        steps.split(","),
        not_after,
        constraints=cons,
    )
    _dump_json(tok_mod.attenuate(token, issuer, holder, sc), out)
    click.echo(f"attenuated -> {out}")


@cli.command()
@click.option("--key", "key_path", required=True)
@click.option("--token", "token_path", required=True)
@click.option("--step", required=True)
@click.option("--ticket", required=True)
@click.option("--branch", required=True)
@click.option("--commit", required=True)
@click.option("--input", "inputs", multiple=True, help="name=path, repeatable")
@click.option("--output", "outputs", multiple=True, help="name=path, repeatable")
@click.option("--context", "contexts", multiple=True,
              help="name=v1,v2 constraint values the work used, repeatable")
@click.option("--store", "store_root", default=".forgegate")
def attest(key_path, token_path, step, ticket, branch, commit, inputs,
           outputs, contexts, store_root):
    key = _load_key(key_path)
    token = _load_json(token_path)
    a = att_mod.create(
        key, token, step, ticket, branch,
        _artifacts(inputs), _artifacts(outputs), commit,
        context=_kv_lists(contexts) or None,
    )
    aid = FileStore(store_root).put(a)
    click.echo(f"attested {step} -> {aid}")


@cli.command()
@click.option("--layout", "layout_path", required=True)
@click.option("--root", "root_pub", required=True, help="root public key (hex)")
@click.option("--ticket", required=True)
@click.option("--branch", required=True)
@click.option("--commit", required=True)
@click.option("--store", "store_root", default=".forgegate")
@click.option("--verify-time", "verify_time", default=None,
              help="ISO-8601 instant; refuses future-dated evidence")
@click.option("--max-age", "max_age", type=int, default=None,
              help="seconds; refuses evidence older than this window")
def verify(layout_path, root_pub, ticket, branch, commit, store_root,
           verify_time, max_age):
    lay = layout_mod.load(layout_path)
    fs = FileStore(store_root)
    atts = fs.for_ticket(ticket)
    for name in getattr(fs, "skipped", []):
        click.echo(f"WARN skipped corrupt evidence file: {name}")
    verdict = gate_mod.verify(atts, lay, root_pub, ticket, branch, commit,
                              verify_time=verify_time,
                              max_age_seconds=max_age)
    for r in verdict.reasons:
        click.echo(("PASS " if verdict.accepted else "FAIL ") + r)
    click.echo("ACCEPTED" if verdict.accepted else "REFUSED")
    sys.exit(0 if verdict.accepted else 1)


@cli.command()
def demo():
    """End-to-end demonstration including a forgery attempt."""
    from .canon import digest_bytes

    root = Key.generate()
    orchestrator = Key.generate()
    implementer = Key.generate()
    tester = Key.generate()

    exp = "2099-01-01T00:00:00+00:00"
    org = tok_mod.mint(
        root, orchestrator.public_hex,
        tok_mod.scope("T-42", "feat/x", ["*"], exp),
    )
    impl_tok = tok_mod.attenuate(
        org, orchestrator, implementer.public_hex,
        tok_mod.scope("T-42", "feat/x", ["implement"], exp),
    )
    test_tok = tok_mod.attenuate(
        org, orchestrator, tester.public_hex,
        tok_mod.scope("T-42", "feat/x", ["test"], exp),
    )

    code = digest_bytes(b"def add(a,b): return a+b")
    report = digest_bytes(b"all tests passed")
    commit = "c0ffee" * 6 + "c0ff"

    layout = layout_mod.validate({
        "name": "code-change",
        "steps": [
            {"name": "implement"},
            {"name": "test", "consumes": ["implement"],
             "distinct_from": ["implement"]},
        ],
    })

    a1 = att_mod.create(implementer, impl_tok, "implement", "T-42", "feat/x",
                        {}, {"src": code}, commit)
    a2 = att_mod.create(tester, test_tok, "test", "T-42", "feat/x",
                        {"src": code}, {"report": report}, commit)
    v = gate_mod.verify([a1, a2], layout, root.public_hex,
                        "T-42", "feat/x", commit)
    click.echo(f"honest run: {'ACCEPTED' if v else 'REFUSED'}")

    forged = att_mod.create(implementer, impl_tok, "test", "T-42", "feat/x",
                            {"src": code}, {"report": report}, commit)
    v2 = gate_mod.verify([a1, forged], layout, root.public_hex,
                         "T-42", "feat/x", commit)
    click.echo(f"forged test step: {'ACCEPTED' if v2 else 'REFUSED'}")
    for r in v2.reasons:
        click.echo(f"  {r}")


if __name__ == "__main__":
    cli()
