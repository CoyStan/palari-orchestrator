#!/usr/bin/env python3
"""Mock broker evidence capture.

This adapter records observed-command evidence for a ticket while keeping the
broker side-effect boundary explicit: real side effects are disabled, no
credentials are loaded, and obvious dangerous commands are refused before
execution.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DANGEROUS_SNIPPETS = (
    "rm -rf",
    "rm -fr",
    "sudo ",
    "curl ",
    "wget ",
    "ssh ",
    "scp ",
    "rsync ",
    "dd ",
    "mkfs",
    "nc ",
    "netcat",
    "git push",
    "git merge",
    "gh pr merge",
    "chmod 777",
    "chown ",
)


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_status(root: Path) -> set[str]:
    result = subprocess.run(
        ["git", "-C", str(root), "status", "--porcelain"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    paths: set[str] = set()
    for raw in result.stdout.decode("utf-8", errors="replace").splitlines():
        if not raw:
            continue
        path = raw[3:] if len(raw) > 3 else raw
        paths.add(path.strip())
    return paths


def refusal_reason(command: list[str]) -> str:
    joined = " ".join(command).lower()
    for snippet in DANGEROUS_SNIPPETS:
        if snippet in joined:
            return f"refused dangerous command pattern: {snippet.strip()}"
    return ""


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run_command(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    out = Path(args.out).resolve()
    command = list(args.command)
    out.mkdir(parents=True, exist_ok=True)

    before = git_status(root)
    reason = refusal_reason(command)
    stdout = b""
    stderr = b""
    exit_code = 126 if reason else 0
    timed_out = False
    executed = False

    if not reason:
        executed = True
        try:
            result = subprocess.run(
                command,
                cwd=root,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=30,
                check=False,
            )
            stdout = result.stdout
            stderr = result.stderr
            exit_code = int(result.returncode)
        except subprocess.TimeoutExpired as exc:
            stdout = exc.stdout or b""
            stderr = (exc.stderr or b"") + b"\nmock broker timeout after 30 seconds\n"
            exit_code = 124
            timed_out = True

    after = git_status(root)
    changed_paths = sorted(after - before)

    (out / "stdout.txt").write_bytes(stdout)
    (out / "stderr.txt").write_bytes(stderr)
    (out / "changed_paths.txt").write_text("\n".join(changed_paths) + ("\n" if changed_paths else ""), encoding="utf-8")
    command_record = {
        "schema_version": "1",
        "ticket": args.ticket,
        "created_at": now(),
        "mode": "mock",
        "side_effects_enabled": False,
        "credentials_available_to_agents": False,
        "network_or_hosted_api_access": False,
        "cwd": str(root),
        "command": command,
    }
    write_json(out / "command.json", command_record)
    summary = {
        **command_record,
        "executed": executed,
        "refused": bool(reason),
        "refusal_reason": reason,
        "timed_out": timed_out,
        "exit_code": exit_code,
        "stdout_sha256": sha256_bytes(stdout),
        "stderr_sha256": sha256_bytes(stderr),
        "changed_paths": changed_paths,
        "artifacts": {
            "command": "command.json",
            "stdout": "stdout.txt",
            "stderr": "stderr.txt",
            "changed_paths": "changed_paths.txt",
        },
    }
    write_json(out / "summary.json", summary)

    rel = out.relative_to(root)
    print(f"broker run: {args.ticket} mock")
    print(f"exit_code: {exit_code}")
    print("side_effects_enabled: false")
    if reason:
        print(f"refused: {reason}")
    print(f"evidence: {rel}")
    return 1 if reason else exit_code


def evidence_items(root: Path, evidence_dir: str, ticket: str) -> list[dict[str, Any]]:
    broker_dir = root / evidence_dir / ticket / "broker"
    if not broker_dir.is_dir():
        return []
    items: list[dict[str, Any]] = []
    for summary_path in sorted(broker_dir.glob("*/summary.json")):
        try:
            data = json.loads(summary_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        data["path"] = str(summary_path.parent.relative_to(root))
        items.append(data)
    return items


def list_evidence(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    items = evidence_items(root, args.evidence_dir, args.ticket)
    data = {
        "ticket": args.ticket,
        "real_side_effects_enabled": False,
        "count": len(items),
        "items": items,
    }
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
        return 0
    print(f"Broker evidence for {args.ticket}")
    print("real_side_effects_enabled: false")
    if not items:
        print("No broker evidence found.")
        return 0
    for item in items:
        command = " ".join(item.get("command", []))
        print(f"- {item['path']}: exit {item.get('exit_code')} command `{command}`")
        if item.get("refused"):
            print(f"  refused: {item.get('refusal_reason')}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command_name", required=True)

    run = sub.add_parser("run")
    run.add_argument("--root", required=True)
    run.add_argument("--ticket", required=True)
    run.add_argument("--out", required=True)
    run.add_argument("command", nargs=argparse.REMAINDER)

    evidence = sub.add_parser("evidence")
    evidence.add_argument("--root", required=True)
    evidence.add_argument("--ticket", required=True)
    evidence.add_argument("--evidence-dir", required=True)
    evidence.add_argument("--json", action="store_true")

    args = parser.parse_args()
    if args.command_name == "run":
        if args.command and args.command[0] == "--":
            args.command = args.command[1:]
        if not args.command:
            raise SystemExit("error: broker run requires a command")
        return run_command(args)
    return list_evidence(args)


if __name__ == "__main__":
    raise SystemExit(main())
