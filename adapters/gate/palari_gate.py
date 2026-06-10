#!/usr/bin/env python3
"""Palari gate adapter.

This is the only code in palari-orchestrator that talks to the vendored
forgegate kernel (gate/forgegate). It owns key material layout, token
minting and attenuation for ticket identities, attestation creation with
automatic hash-flow wiring, verification, and the JSON status feed used by
`palari snapshot` and the operator console.

Design rules inherited from forgegate and kept here:

  * Tickets are pure data. This adapter reads ticket frontmatter only to
    discover the branch name; nothing in a ticket can mint, widen, or
    substitute for a token.
  * Verification always passes verify_time and max_age so backdated and
    stale evidence are refused (see gate/README.md, threat model notes).
  * Fail closed. Malformed anything yields a refusal or a nonzero exit with
    a reason, never a silent pass.

Commit binding policy (adapter level, the kernel stays strict):
  The expected commit for a ticket is resolved as
    1. an explicit --commit argument,
    2. else the tip of the ticket's declared branch if that ref exists,
    3. else HEAD.
  If stored attestations all bind one older commit, that commit is accepted
  instead only when it is an ancestor of the resolved tip and every path
  changed between the two lies inside governance bookkeeping directories
  (evidence, tickets, reports, handoffs). Committing the evidence trail
  itself must not invalidate the evidence; changing the work must.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_FALLBACK = HERE.parent.parent
GATE_PKG_DIR = None


def _find_root(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    env = os.environ.get("PALARI_ROOT")
    if env:
        return Path(env).resolve()
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        if out:
            return Path(out).resolve()
    except (OSError, subprocess.CalledProcessError):
        pass
    return REPO_FALLBACK


def _import_kernel(root: Path):
    global GATE_PKG_DIR
    GATE_PKG_DIR = root / "gate"
    sys.path.insert(0, str(GATE_PKG_DIR))
    try:
        import forgegate  # noqa: F401
        from forgegate import attest, gate, layout, token  # noqa: F401
        from forgegate.canon import digest_bytes, digest_file  # noqa: F401
        from forgegate.keys import Key  # noqa: F401
        from forgegate.store import FileStore  # noqa: F401
    except Exception as exc:  # pragma: no cover - environment dependent
        print(
            "gate: the forgegate kernel is unavailable "
            f"({exc.__class__.__name__}: {exc}). "
            "Install python3 with the 'cryptography' package, or disable the "
            "gate in palari.config.yaml.",
            file=sys.stderr,
        )
        raise SystemExit(3)
    import forgegate
    return forgegate


# ---------------------------------------------------------------------------
# Config

DEFAULTS = {
    "enabled": False,
    "layout": "layouts/palari-change.yml",
    "keys_dir": ".palari/gate/keys",
    "root_pub_file": ".palari/gate/root.pub",
    "token_validity_days": 365,
    "ticket_token_days": 30,
    "max_age_seconds": 86400,
    "ci_key": "ci",
}

PATH_KEYS = {
    "evidence_dir": "reports/evidence",
    "tickets_open_dir": "tickets/open",
    "tickets_closed_dir": "tickets/closed",
    "reports_dir": "reports",
    "handoffs_dir": "handoffs",
}


def _parse_config_text(text: str) -> dict:
    """Parse the small subset of YAML palari.config.yaml uses.

    Prefers PyYAML when importable; otherwise reads top-level scalars and one
    level of nesting under `gate:`, which is all this adapter needs.
    """
    try:
        import yaml

        data = yaml.safe_load(text) or {}
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    data: dict = {}
    current: dict | None = None
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        match = re.match(r"^(\s*)([A-Za-z0-9_.-]+):\s*(.*)$", line)
        if not match:
            continue
        indent, key, value = match.groups()
        if not indent:
            if value == "":
                current = {}
                data[key] = current
            else:
                data[key] = value.strip().strip("'\"")
                current = None
        elif current is not None and len(indent) <= 4 and value != "":
            current[key] = value.strip().strip("'\"")
    return data


class Config:
    def __init__(self, root: Path):
        self.root = root
        path = root / "palari.config.yaml"
        raw = _parse_config_text(path.read_text(encoding="utf-8")) if path.is_file() else {}
        gate_raw = raw.get("gate") if isinstance(raw.get("gate"), dict) else {}
        self.gate: dict = dict(DEFAULTS)
        for key in DEFAULTS:
            if key in gate_raw and gate_raw[key] is not None:
                self.gate[key] = gate_raw[key]
        self.paths = {
            key: str(raw.get(key) or default) for key, default in PATH_KEYS.items()
        }

    @property
    def enabled(self) -> bool:
        value = self.gate["enabled"]
        if isinstance(value, bool):
            return value
        return str(value).strip().lower() in ("true", "1", "yes", "on")

    def keys_dir(self) -> Path:
        return self.root / str(self.gate["keys_dir"])

    def root_pub_file(self) -> Path:
        return self.root / str(self.gate["root_pub_file"])

    def layout_path(self) -> Path:
        return self.root / str(self.gate["layout"])

    def evidence_dir(self) -> Path:
        return self.root / self.paths["evidence_dir"]

    def bookkeeping_prefixes(self) -> list[str]:
        return [
            self.paths["evidence_dir"].rstrip("/") + "/",
            self.paths["tickets_open_dir"].rstrip("/") + "/",
            self.paths["tickets_closed_dir"].rstrip("/") + "/",
            self.paths["reports_dir"].rstrip("/") + "/",
            self.paths["handoffs_dir"].rstrip("/") + "/",
        ]


# ---------------------------------------------------------------------------
# Repo helpers

def _git(root: Path, *args: str) -> str | None:
    try:
        res = subprocess.run(
            ["git", "-C", str(root), *args],
            capture_output=True, text=True, errors="replace", check=True,
        )
        return res.stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _iso(dt: datetime) -> str:
    return dt.isoformat(timespec="seconds")


FRONTMATTER_RE = re.compile(r"^---\s*$")


def _frontmatter_value(path: Path, key: str) -> str:
    inside = False
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if FRONTMATTER_RE.match(line):
                if inside:
                    break
                inside = True
                continue
            if not inside:
                continue
            match = re.match(rf"^{re.escape(key)}:\s*(.*)$", line)
            if match:
                return match.group(1).strip().strip("'\"")
    except OSError:
        pass
    return ""


def find_ticket_file(cfg: Config, ticket: str) -> Path | None:
    for key in ("tickets_open_dir", "tickets_closed_dir"):
        directory = cfg.root / cfg.paths[key]
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob(f"{ticket}-*.md")):
            return path
        exact = directory / f"{ticket}.md"
        if exact.is_file():
            return exact
    return None


def ticket_branch(cfg: Config, ticket: str) -> str:
    file = find_ticket_file(cfg, ticket)
    if file is not None:
        declared = _frontmatter_value(file, "branch")
        if declared:
            return declared
    return f"ticket/{ticket}"


def resolve_commit(cfg: Config, ticket: str, explicit: str | None) -> tuple[str, str]:
    """Returns (commit, source)."""
    if explicit:
        resolved = _git(cfg.root, "rev-parse", "--verify", "--quiet",
                        f"{explicit}^{{commit}}")
        return (resolved or explicit), "explicit"
    branch = ticket_branch(cfg, ticket)
    tip = _git(cfg.root, "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}")
    if tip:
        return tip, f"branch {branch}"
    head = _git(cfg.root, "rev-parse", "HEAD") or ""
    return head, "HEAD"


def _bookkeeping_only(cfg: Config, old: str, new: str) -> bool:
    if not old or not new or old == new:
        return old == new
    ancestor = subprocess.run(
        ["git", "-C", str(cfg.root), "merge-base", "--is-ancestor", old, new],
        capture_output=True,
    ).returncode == 0
    if not ancestor:
        return False
    diff = _git(cfg.root, "diff", "--name-only", old, new)
    if diff is None:
        return False
    prefixes = tuple(cfg.bookkeeping_prefixes())
    for path in diff.splitlines():
        path = path.strip()
        if path and not path.startswith(prefixes):
            return False
    return True


# ---------------------------------------------------------------------------
# Key and token storage

def _key_path(cfg: Config, name: str) -> Path:
    return cfg.keys_dir() / f"{name}.key"


def _token_path(cfg: Config, name: str, ticket: str | None = None) -> Path:
    if ticket:
        return cfg.keys_dir() / f"{name}-{ticket}.token.json"
    return cfg.keys_dir() / f"{name}.token.json"


def _load_key(fg, cfg: Config, name: str):
    path = _key_path(cfg, name)
    if not path.is_file():
        print(f"gate: missing key '{name}' ({path}); run `palari gate init` "
              f"or `palari gate setup-ticket TICKET` first", file=sys.stderr)
        raise SystemExit(2)
    return fg.Key.from_hex(path.read_text(encoding="utf-8").strip())


def _ensure_key(fg, cfg: Config, name: str):
    path = _key_path(cfg, name)
    if path.is_file():
        return fg.Key.from_hex(path.read_text(encoding="utf-8").strip()), False
    cfg.keys_dir().mkdir(parents=True, exist_ok=True)
    key = fg.Key.generate()
    path.write_text(key.to_hex(), encoding="utf-8")
    try:
        path.chmod(0o600)
    except OSError:
        pass
    return key, True


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _dump_json(obj, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=1, sort_keys=True), encoding="utf-8")


def _root_pub(cfg: Config) -> str:
    path = cfg.root_pub_file()
    if not path.is_file():
        print(f"gate: missing root public key ({path}); run `palari gate init`",
              file=sys.stderr)
        raise SystemExit(2)
    return path.read_text(encoding="utf-8").strip()


def fingerprint(public_hex: str) -> str:
    if not public_hex:
        return ""
    return hashlib.sha256(bytes.fromhex(public_hex)).hexdigest()[:12]


def _store(cfg: Config, ticket: str):
    from forgegate.store import FileStore

    return FileStore(str(cfg.evidence_dir() / ticket / "gate"))


STEP_IDENTITY = {"implement": "implementer", "test": None, "review": "reviewer"}


def step_identities(cfg: Config) -> dict[str, str]:
    return {
        "implement": "implementer",
        "test": str(cfg.gate["ci_key"]),
        "review": "reviewer",
    }


# ---------------------------------------------------------------------------
# Commands

def cmd_init(fg, cfg: Config, args) -> int:
    root_key, root_new = _ensure_key(fg, cfg, "root")
    orch_key, orch_new = _ensure_key(fg, cfg, "orchestrator")
    pub_file = cfg.root_pub_file()
    pub_file.parent.mkdir(parents=True, exist_ok=True)
    pub_file.write_text(root_key.public_hex + "\n", encoding="utf-8")

    token_file = _token_path(cfg, "orchestrator")
    if not token_file.is_file() or args.force:
        not_after = _iso(_now() + timedelta(days=int(cfg.gate["token_validity_days"])))
        scope = fg.token.scope("*", "*", ["*"], not_after)
        _dump_json(fg.token.mint(root_key, orch_key.public_hex, scope), token_file)

    rel = pub_file.relative_to(cfg.root)
    print(f"gate init: root key {'created' if root_new else 'kept'} "
          f"(fingerprint {fingerprint(root_key.public_hex)})")
    print(f"gate init: orchestrator key {'created' if orch_new else 'kept'} "
          f"(fingerprint {fingerprint(orch_key.public_hex)})")
    print(f"gate init: root public key written to {rel}")
    print(f"gate init: orchestrator token at "
          f"{token_file.relative_to(cfg.root)}")
    print("gate init: private keys live under "
          f"{cfg.keys_dir().relative_to(cfg.root)} and are gitignored")
    return 0


def _grant(fg, cfg: Config, name: str, ticket: str, steps: list[str],
           days: int) -> Path:
    orch_key = _load_key(fg, cfg, "orchestrator")
    orch_token = _load_json(_token_path(cfg, "orchestrator"))
    holder_key, _ = _ensure_key(fg, cfg, name)
    branch = ticket_branch(cfg, ticket)
    not_after = _iso(_now() + timedelta(days=days))
    scope = fg.token.scope(ticket, branch, steps, not_after)
    token = fg.token.attenuate(orch_token, orch_key, holder_key.public_hex, scope)
    out = _token_path(cfg, name, ticket)
    _dump_json(token, out)
    return out


def cmd_setup_ticket(fg, cfg: Config, args) -> int:
    days = int(args.days or cfg.gate["ticket_token_days"])
    identities = step_identities(cfg)
    for step, name in identities.items():
        out = _grant(fg, cfg, name, args.ticket, [step], days)
        key = _load_key(fg, cfg, name)
        print(f"gate grant: {name} may attest '{step}' on {args.ticket} "
              f"(key {fingerprint(key.public_hex)}, token "
              f"{out.relative_to(cfg.root)})")
    return 0


def cmd_grant(fg, cfg: Config, args) -> int:
    steps = [s for s in args.steps.split(",") if s]
    if not steps:
        print("gate grant: --steps requires at least one step", file=sys.stderr)
        return 2
    days = int(args.days or cfg.gate["ticket_token_days"])
    out = _grant(fg, cfg, args.holder, args.ticket, steps, days)
    key = _load_key(fg, cfg, args.holder)
    print(f"gate grant: {args.holder} may attest {','.join(steps)} on "
          f"{args.ticket} (key {fingerprint(key.public_hex)}, token "
          f"{out.relative_to(cfg.root)})")
    return 0


def _hash_artifacts(fg, cfg: Config, pairs: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for pair in pairs:
        if "=" not in pair:
            print(f"gate attest: artifact must be name=path: {pair}",
                  file=sys.stderr)
            raise SystemExit(2)
        name, rel = pair.split("=", 1)
        path = (cfg.root / rel) if not os.path.isabs(rel) else Path(rel)
        if not path.is_file():
            print(f"gate attest: artifact file missing: {rel}", file=sys.stderr)
            raise SystemExit(2)
        out[name] = fg.canon.digest_file(str(path))
    return out


def _stored_outputs(cfg: Config, ticket: str, step: str) -> dict[str, str] | None:
    store = _store(cfg, ticket)
    matches = [a for a in store.for_ticket(ticket) if a.get("step") == step]
    if len(matches) != 1:
        return None
    return dict(matches[0].get("outputs", {}))


def _do_attest(fg, cfg: Config, *, ticket: str, step: str, key_name: str,
               inputs: dict[str, str], outputs: dict[str, str],
               commit: str | None) -> int:
    key = _load_key(fg, cfg, key_name)
    token_file = _token_path(cfg, key_name, ticket)
    if not token_file.is_file():
        print(f"gate attest: no token for {key_name} on {ticket}; run "
              f"`palari gate setup-ticket {ticket}`", file=sys.stderr)
        return 2
    token = _load_json(token_file)
    branch = ticket_branch(cfg, ticket)
    bound, source = resolve_commit(cfg, ticket, commit)
    if not bound:
        print("gate attest: cannot resolve a commit to bind", file=sys.stderr)
        return 2
    # Fail fast on an out-of-scope attestation. This is UX only: a forger
    # can bypass the adapter and sign anything, and the gate refuses it at
    # verify time. Honest mistakes deserve the early, exact message.
    leaf_scope = fg.token.leaf(token)["scope"]
    if not fg.token.scope_authorizes(leaf_scope, ticket, branch, step,
                                     _iso(_now())):
        print(f"gate attest: the {key_name} token does not authorize step "
              f"'{step}' on {ticket} ({branch}); the gate would refuse this "
              f"attestation. Grant the right scope with `palari gate grant` "
              f"or use the identity that holds it.", file=sys.stderr)
        return 2
    store = _store(cfg, ticket)
    existing = [a for a in store.for_ticket(ticket) if a.get("step") == step]
    if existing:
        for att in existing:
            aid = fg.attest.att_id(att)
            stale = Path(store.dir) / f"{aid}.json"
            if stale.is_file():
                stale.unlink()
        print(f"gate attest: superseded {len(existing)} earlier "
              f"'{step}' attestation(s); duplicates are refused by the gate")
    att = fg.attest.create(key, token, step, ticket, branch, inputs, outputs,
                           bound)
    aid = store.put(att)
    rel = Path(store.dir).relative_to(cfg.root)
    print(f"gate attest: {step} on {ticket} signed by {key_name} "
          f"({fingerprint(key.public_hex)}), bound to {bound[:12]} "
          f"({source}) -> {rel}/{aid}.json")
    return 0


def cmd_attest(fg, cfg: Config, args) -> int:
    inputs = _hash_artifacts(fg, cfg, args.input or [])
    outputs = _hash_artifacts(fg, cfg, args.output or [])
    if args.consumes:
        upstream = _stored_outputs(cfg, args.ticket, args.consumes)
        if upstream is None:
            print(f"gate attest: cannot consume '{args.consumes}': missing or "
                  f"ambiguous upstream attestation", file=sys.stderr)
            return 2
        merged = dict(upstream)
        merged.update(inputs)
        inputs = merged
    return _do_attest(fg, cfg, ticket=args.ticket, step=args.step,
                      key_name=args.key, inputs=inputs, outputs=outputs,
                      commit=args.commit)


def cmd_attest_implement(fg, cfg: Config, args) -> int:
    ticket = args.ticket
    branch = ticket_branch(cfg, ticket)
    bound, _ = resolve_commit(cfg, ticket, args.commit)
    base = args.base
    if not base:
        base = _frontmatter_value(find_ticket_file(cfg, ticket) or Path("/dev/null"),
                                  "target_branch") or "main"
    merge_base = _git(cfg.root, "merge-base", base, bound) or base
    diff = _git(cfg.root, "diff", "--binary", merge_base, bound)
    if diff is None:
        print(f"gate attest: cannot diff {merge_base}..{bound[:12]} for the "
              f"implement artifact", file=sys.stderr)
        return 2
    outputs = {"diff": fg.canon.digest_bytes(diff.encode("utf-8"))}
    print(f"gate attest: implement artifact is the diff {merge_base[:12] if len(merge_base) >= 12 else merge_base}..{bound[:12]} "
          f"on {branch}")
    return _do_attest(fg, cfg, ticket=ticket, step="implement",
                      key_name=args.key or "implementer", inputs={},
                      outputs=outputs, commit=bound)


def cmd_attest_test(fg, cfg: Config, args) -> int:
    ticket = args.ticket
    evidence = cfg.evidence_dir() / ticket
    artifacts = []
    for name in ("manifest.json", "junit.xml", "palari.sarif", "verification.log"):
        path = evidence / name
        if not path.is_file():
            print(f"gate attest: evidence artifact missing: "
                  f"{path.relative_to(cfg.root)}; run `palari ci {ticket}` first",
                  file=sys.stderr)
            return 2
        artifacts.append(f"{name}={path.relative_to(cfg.root)}")
    outputs = _hash_artifacts(fg, cfg, artifacts)
    upstream = _stored_outputs(cfg, ticket, "implement")
    if upstream is None:
        print("gate attest: the implement step is not attested yet; the test "
              "attestation must consume it. Run "
              f"`palari gate attest-implement {ticket}` first", file=sys.stderr)
        return 2
    return _do_attest(fg, cfg, ticket=ticket, step="test",
                      key_name=args.key or str(cfg.gate["ci_key"]),
                      inputs=upstream, outputs=outputs, commit=args.commit)


def cmd_attest_review(fg, cfg: Config, args) -> int:
    ticket = args.ticket
    upstream = _stored_outputs(cfg, ticket, "test")
    if upstream is None:
        print("gate attest: the test step is not attested yet; the review "
              "attestation must consume it. Run "
              f"`palari gate attest-test {ticket}` first", file=sys.stderr)
        return 2
    note = cfg.root / cfg.paths["reports_dir"] / f"{ticket}-reviewer-note.md"
    if note.is_file():
        outputs = {"approval": fg.canon.digest_file(str(note))}
        print(f"gate attest: review approval binds "
              f"{note.relative_to(cfg.root)}")
    else:
        bound, _ = resolve_commit(cfg, ticket, args.commit)
        outputs = {"approval": fg.canon.digest_bytes(
            f"approved:{ticket}:{bound}".encode("utf-8"))}
        print("gate attest: no reviewer note found; approval binds the "
              "canonical approval string")
    return _do_attest(fg, cfg, ticket=ticket, step="review",
                      key_name=args.key or "reviewer", inputs=upstream,
                      outputs=outputs, commit=args.commit)


def _verify(fg, cfg: Config, ticket: str, commit: str | None):
    layout = fg.layout.load(str(cfg.layout_path()))
    root_pub = _root_pub(cfg)
    branch = ticket_branch(cfg, ticket)
    store = _store(cfg, ticket)
    atts = store.for_ticket(ticket)
    skipped = list(getattr(store, "skipped", []))
    expected, source = resolve_commit(cfg, ticket, commit)
    bound = {a.get("commit") for a in atts
             if isinstance(a, dict) and a.get("commit")}
    if commit is None and len(bound) == 1:
        only = next(iter(bound))
        if only and only != expected and _bookkeeping_only(cfg, only, expected):
            expected, source = only, "attested commit (bookkeeping-only drift)"
    verdict = fg.gate.verify(
        atts, layout, root_pub, ticket, branch, expected,
        verify_time=_iso(_now()),
        max_age_seconds=int(cfg.gate["max_age_seconds"]),
    )
    return verdict, expected, source, skipped, atts


def cmd_verify(fg, cfg: Config, args) -> int:
    verdict, expected, source, skipped, _ = _verify(fg, cfg, args.ticket,
                                                    args.commit)
    if args.json:
        print(json.dumps({
            "ticket": args.ticket,
            "accepted": verdict.accepted,
            "reasons": verdict.reasons,
            "commit": expected,
            "commit_source": source,
            "skipped_evidence_files": skipped,
        }, indent=2))
    else:
        for name in skipped:
            print(f"WARN skipped corrupt evidence file: {name}")
        for reason in verdict.reasons:
            print(("PASS " if verdict.accepted else "FAIL ") + reason)
        print(f"commit: {expected[:12]} ({source})")
        print("ACCEPTED" if verdict.accepted else "REFUSED")
    return 0 if verdict.accepted else 1


def _ticket_ids(cfg: Config) -> list[str]:
    ids: set[str] = set()
    for key in ("tickets_open_dir", "tickets_closed_dir"):
        directory = cfg.root / cfg.paths[key]
        if not directory.is_dir():
            continue
        for path in directory.glob("*.md"):
            value = _frontmatter_value(path, "id")
            if value:
                ids.add(value)
    evidence = cfg.evidence_dir()
    if evidence.is_dir():
        for child in evidence.iterdir():
            if (child / "gate" / "attestations").is_dir():
                ids.add(child.name)
    return sorted(ids)


def _ticket_status(fg, cfg: Config, ticket: str) -> dict:
    store_dir = cfg.evidence_dir() / ticket / "gate" / "attestations"
    steps: dict[str, dict] = {}
    has_any = store_dir.is_dir() and any(store_dir.glob("*.json"))
    layout = fg.layout.load(str(cfg.layout_path()))
    step_names = fg.layout.step_names(layout)
    atts = _store(cfg, ticket).for_ticket(ticket) if has_any else []
    by_step: dict[str, list[dict]] = {}
    for att in atts:
        by_step.setdefault(str(att.get("step", "")), []).append(att)
    for name in step_names:
        found = by_step.get(name, [])
        if not found:
            steps[name] = {"attested": False}
            continue
        att = found[0]
        steps[name] = {
            "attested": True,
            "duplicates": len(found) > 1,
            "signer": fingerprint(str(att.get("signer", ""))),
            "ts": att.get("ts", ""),
            "signature_valid": fg.attest.signature_valid(att),
            "outputs": sorted((att.get("outputs") or {}).keys()),
        }
    result: dict = {"steps": steps, "attested_steps": sum(
        1 for s in steps.values() if s.get("attested")), "total_steps": len(step_names)}
    if has_any:
        verdict, expected, source, skipped, _ = _verify(fg, cfg, ticket, None)
        result["verdict"] = {
            "accepted": verdict.accepted,
            "reasons": verdict.reasons,
            "commit": expected[:12],
            "commit_source": source,
            "skipped_evidence_files": skipped,
        }
    else:
        result["verdict"] = None
    return result


def cmd_status(fg_or_none, cfg: Config, args) -> int:
    payload: dict = {
        "enabled": cfg.enabled,
        "available": fg_or_none is not None,
        "layout": str(cfg.gate["layout"]),
        "max_age_seconds": int(cfg.gate["max_age_seconds"]),
        "root_fingerprint": "",
        "initialized": False,
        "tickets": {},
    }
    if fg_or_none is not None:
        pub = cfg.root_pub_file()
        if pub.is_file():
            payload["initialized"] = True
            payload["root_fingerprint"] = fingerprint(
                pub.read_text(encoding="utf-8").strip())
        if payload["initialized"] and cfg.layout_path().is_file():
            wanted = [args.ticket] if args.ticket else _ticket_ids(cfg)
            for ticket in wanted:
                try:
                    payload["tickets"][ticket] = _ticket_status(
                        fg_or_none, cfg, ticket)
                except Exception as exc:
                    payload["tickets"][ticket] = {
                        "error": f"{exc.__class__.__name__}: {exc}"}
    print(json.dumps(payload, indent=2 if args.pretty else None,
                     sort_keys=True))
    return 0


# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="palari gate")
    parser.add_argument("--root", default=None)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("init", help="create root and orchestrator keys")
    p.add_argument("--force", action="store_true")

    p = sub.add_parser("setup-ticket",
                       help="grant implement, test, and review tokens")
    p.add_argument("ticket")
    p.add_argument("--days", type=int, default=None)

    p = sub.add_parser("grant", help="grant a custom step token")
    p.add_argument("--ticket", required=True)
    p.add_argument("--holder", required=True)
    p.add_argument("--steps", required=True)
    p.add_argument("--days", type=int, default=None)

    p = sub.add_parser("attest", help="sign a step with explicit artifacts")
    p.add_argument("--ticket", required=True)
    p.add_argument("--step", required=True)
    p.add_argument("--key", required=True)
    p.add_argument("--input", action="append")
    p.add_argument("--output", action="append")
    p.add_argument("--consumes", default=None)
    p.add_argument("--commit", default=None)

    p = sub.add_parser("attest-implement", help="sign the ticket diff")
    p.add_argument("ticket")
    p.add_argument("--key", default=None)
    p.add_argument("--base", default=None)
    p.add_argument("--commit", default=None)

    p = sub.add_parser("attest-test", help="sign the CI evidence bundle")
    p.add_argument("ticket")
    p.add_argument("--key", default=None)
    p.add_argument("--commit", default=None)

    p = sub.add_parser("attest-review", help="sign the fresh review")
    p.add_argument("ticket")
    p.add_argument("--key", default=None)
    p.add_argument("--commit", default=None)

    p = sub.add_parser("verify", help="run the forge-proof accept gate")
    p.add_argument("ticket")
    p.add_argument("--commit", default=None)
    p.add_argument("--json", action="store_true")

    p = sub.add_parser("status", help="JSON gate status for snapshots")
    p.add_argument("--ticket", default=None)
    p.add_argument("--pretty", action="store_true")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    root = _find_root(args.root)
    cfg = Config(root)

    if args.command == "status":
        fg = None
        try:
            fg = _import_kernel(root)
        except SystemExit:
            fg = None
        return cmd_status(fg, cfg, args)

    fg = _import_kernel(root)
    handlers = {
        "init": cmd_init,
        "setup-ticket": cmd_setup_ticket,
        "grant": cmd_grant,
        "attest": cmd_attest,
        "attest-implement": cmd_attest_implement,
        "attest-test": cmd_attest_test,
        "attest-review": cmd_attest_review,
        "verify": cmd_verify,
    }
    return handlers[args.command](fg, cfg, args)


if __name__ == "__main__":
    raise SystemExit(main())
