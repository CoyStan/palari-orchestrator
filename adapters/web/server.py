#!/usr/bin/env python3
"""Palari Console: optional local web dashboard for Palari Orchestrator."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import time
import urllib.parse
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
STATIC_DIR = HERE / "static"

DEFAULT_CONFIG = {
    "project_name": "Palari Orchestrator",
    "tickets_open_dir": "tickets/open",
    "tickets_closed_dir": "tickets/closed",
    "reports_dir": "reports",
    "human_reports_dir": "reports/human",
    "handoffs_dir": "handoffs",
    "evidence_dir": "reports/evidence",
    "default_branch": "main",
    "claim_lease_seconds": "300",
    "scope_overlap_policy": "block",
}


def run(root: Path, args: list[str], timeout: int = 5) -> dict[str, Any]:
    try:
        completed = subprocess.run(
            args,
            cwd=root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return {
            "ok": completed.returncode == 0,
            "code": completed.returncode,
            "stdout": completed.stdout.strip(),
            "stderr": completed.stderr.strip(),
        }
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"ok": False, "code": 127, "stdout": "", "stderr": str(exc)}


def read_text(path: Path, limit: int = 256_000) -> str:
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            return handle.read(limit)
    except OSError:
        return ""


def parse_config(root: Path) -> dict[str, Any]:
    config = dict(DEFAULT_CONFIG)
    path = root / "palari.config.yaml"
    if not path.exists():
        return config

    current_key = ""
    for raw in read_text(path).splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if re.match(r"^[A-Za-z0-9_]+:", line):
            key, value = line.split(":", 1)
            value = value.strip().strip("'\"")
            current_key = key
            config[key] = [] if value == "" else value
            if value == "[]":
                config[key] = []
        elif current_key and line.lstrip().startswith("- "):
            value = line.lstrip()[2:].strip().strip("'\"")
            if not isinstance(config.get(current_key), list):
                config[current_key] = []
            config[current_key].append(value)
    return config


def parse_frontmatter(path: Path) -> dict[str, Any]:
    text = read_text(path)
    if not text.startswith("---\n"):
        return {}
    lines = text.splitlines()
    data: dict[str, Any] = {}
    key = ""
    for line in lines[1:]:
        if line == "---":
            break
        if re.match(r"^[A-Za-z0-9_]+:", line):
            key, value = line.split(":", 1)
            value = value.strip().strip("'\"")
            if value == "[]":
                data[key] = []
            elif value:
                data[key] = value
            else:
                data[key] = []
        elif key and line.lstrip().startswith("- "):
            value = line.lstrip()[2:].strip().strip("'\"")
            if not isinstance(data.get(key), list):
                data[key] = []
            data[key].append(value)
    return data


def md_files(root: Path, rel: str) -> list[Path]:
    directory = root / rel
    if not directory.exists():
        return []
    return sorted(
        path
        for path in directory.iterdir()
        if path.is_file()
        and path.name != "README.md"
        and path.suffix.lower() in {".md", ".markdown"}
    )


def list_tickets(root: Path, config: dict[str, Any]) -> list[dict[str, Any]]:
    tickets: list[dict[str, Any]] = []
    for state, rel in (
        ("active", str(config["tickets_open_dir"])),
        ("accepted", str(config["tickets_closed_dir"])),
    ):
        for path in md_files(root, rel):
            data = parse_frontmatter(path)
            ticket_id = str(data.get("id") or path.stem)
            evidence = evidence_summary(root, str(config["evidence_dir"]), ticket_id)
            tickets.append(
                {
                    "id": ticket_id,
                    "title": data.get("title") or ticket_id,
                    "status": data.get("status") or ("accepted" if state == "accepted" else "open"),
                    "risk": data.get("risk") or "R1",
                    "priority": data.get("priority") or "P2",
                    "stream": data.get("stream") or "process",
                    "state": state,
                    "path": str(path.relative_to(root)),
                    "allowed_paths": data.get("allowed_paths") or [],
                    "forbidden_paths": data.get("forbidden_paths") or [],
                    "verification": data.get("verification") or [],
                    "claimed_by": scalar(data.get("claimed_by")),
                    "claim_token": scalar(data.get("claim_token")),
                    "claim_expires_at": scalar(data.get("claim_expires_at")),
                    "claim_heartbeat_at": scalar(data.get("claim_heartbeat_at")),
                    "requires_review": data.get("requires_review") == "true",
                    "requires_human_confirmation": data.get("requires_human_confirmation") == "true",
                    "product_feel_review": data.get("product_feel_review") or "not-applicable",
                    "branch": scalar(data.get("branch")),
                    "worktree": scalar(data.get("worktree")),
                    "evidence": evidence,
                    "reports": report_summary(root, config, ticket_id),
                    "lease": lease_state(data),
                }
            )
    return tickets


def scalar(value: Any) -> str:
    if isinstance(value, list):
        return ""
    return "" if value is None else str(value)


def parse_time(value: str) -> float:
    if not value:
        return 0
    try:
        parsed = datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")
        return parsed.replace(tzinfo=timezone.utc).timestamp()
    except ValueError:
        return 0


def lease_state(data: dict[str, Any]) -> dict[str, Any]:
    expires_at = scalar(data.get("claim_expires_at"))
    expires = parse_time(expires_at)
    now = time.time()
    if not scalar(data.get("claim_token")):
        status = "none"
    elif expires and expires < now:
        status = "expired"
    elif expires and expires - now < 90:
        status = "expiring"
    else:
        status = "active"
    return {
        "status": status,
        "expires_at": expires_at,
        "seconds_remaining": max(0, int(expires - now)) if expires else None,
    }


def evidence_summary(root: Path, evidence_dir: str, ticket_id: str) -> dict[str, Any]:
    directory = root / evidence_dir / ticket_id
    files = sorted(path.name for path in directory.iterdir() if path.is_file()) if directory.exists() else []
    return {
        "path": str(directory.relative_to(root)) if directory.exists() else "",
        "files": files,
        "has_log": "verification.log" in files,
        "has_junit": "junit.xml" in files,
        "has_sarif": "palari.sarif" in files,
        "file_count": len(files),
    }


def report_summary(root: Path, config: dict[str, Any], ticket_id: str) -> dict[str, bool]:
    reports_dir = root / str(config["reports_dir"])
    human_dir = root / str(config["human_reports_dir"])
    reports = [path.name for path in reports_dir.glob(f"*{ticket_id}*.md")] if reports_dir.exists() else []
    human = [path.name for path in human_dir.glob(f"*{ticket_id}*.md")] if human_dir.exists() else []
    return {
        "technical": any("technical" in name.lower() for name in reports),
        "reviewer": any("reviewer" in name.lower() for name in reports),
        "product_feel": any("product" in name.lower() for name in reports),
        "human": bool(human),
    }


def path_prefix(pattern: str) -> str:
    pattern = pattern.lstrip("./")
    pattern = re.sub(r"/\*\*$", "", pattern)
    pattern = re.sub(r"/\*$", "", pattern)
    return pattern.rsplit("/", 1)[0] if "*" in pattern and "/" in pattern else pattern.replace("*", "")


def overlap(left: str, right: str, ignored: set[str]) -> bool:
    if left in ignored or right in ignored:
        return False
    left_prefix = path_prefix(left)
    right_prefix = path_prefix(right)
    if not left_prefix or not right_prefix:
        return False
    return (
        left == right
        or left_prefix == right_prefix
        or left_prefix.startswith(f"{right_prefix}/")
        or right_prefix.startswith(f"{left_prefix}/")
    )


def scope_overlaps(tickets: list[dict[str, Any]], config: dict[str, Any]) -> list[dict[str, str]]:
    ignored = set(config.get("concurrency_ignored_overlap_paths") or [])
    ignored.update({"tickets/**", "reports/**", "reports/human/**", "handoffs/**", ".palari/**"})
    active = [ticket for ticket in tickets if ticket["status"] in {"open", "claimed", "reopened", "in-review"}]
    findings: list[dict[str, str]] = []
    for index, left in enumerate(active):
        for right in active[index + 1 :]:
            for left_pattern in left["allowed_paths"]:
                for right_pattern in right["allowed_paths"]:
                    if overlap(str(left_pattern), str(right_pattern), ignored):
                        findings.append(
                            {
                                "left": left["id"],
                                "right": right["id"],
                                "left_pattern": str(left_pattern),
                                "right_pattern": str(right_pattern),
                            }
                        )
    return findings


def workflow_state(root: Path) -> dict[str, Any]:
    workflow = root / ".github/workflows/palari.yml"
    ruleset = root / ".github/palari-required-checks.ruleset.json"
    workflow_text = read_text(workflow)
    return {
        "workflow_installed": workflow.exists(),
        "ruleset_template": ruleset.exists(),
        "merge_group": "merge_group" in workflow_text,
        "attestation": "actions/attest" in workflow_text,
        "sarif": "upload-sarif" in workflow_text,
        "workflow_path": ".github/workflows/palari.yml",
        "ruleset_path": ".github/palari-required-checks.ruleset.json",
    }


def snapshot(root: Path) -> dict[str, Any]:
    config = parse_config(root)
    tickets = list_tickets(root, config)
    overlaps = scope_overlaps(tickets, config)
    git_status = run(root, ["git", "status", "--short", "--branch"])
    palari_status = run(root, ["./bin/palari", "status"])
    counts = {status: 0 for status in ["open", "claimed", "blocked", "needs-human", "in-review", "reopened", "accepted"]}
    for ticket in tickets:
        counts[ticket["status"]] = counts.get(ticket["status"], 0) + 1

    stale_claims = [ticket for ticket in tickets if ticket["lease"]["status"] == "expired"]
    missing_evidence = [
        ticket
        for ticket in tickets
        if ticket["status"] in {"in-review", "accepted"} and not ticket["evidence"]["has_log"]
    ]
    branch = run(root, ["git", "branch", "--show-current"])

    return {
        "project": config.get("project_name", "Palari Orchestrator"),
        "root": str(root),
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "config": {
            "default_branch": config.get("default_branch", "main"),
            "scope_overlap_policy": config.get("scope_overlap_policy", "block"),
            "claim_lease_seconds": config.get("claim_lease_seconds", "300"),
            "evidence_dir": config.get("evidence_dir", "reports/evidence"),
        },
        "counts": counts,
        "tickets": tickets,
        "overlaps": overlaps,
        "workflow": workflow_state(root),
        "health": {
            "status_ok": palari_status["ok"],
            "dirty_paths": len([line for line in git_status["stdout"].splitlines() if line and not line.startswith("##")]),
            "stale_claims": len(stale_claims),
            "missing_evidence": len(missing_evidence),
            "overlaps": len(overlaps),
        },
        "git": {
            "branch": branch["stdout"] or "detached",
            "status": git_status["stdout"],
        },
        "palari_status": palari_status,
        "commands": {
            "status": "./bin/palari status",
            "lint": "./bin/palari lint",
            "scope_overlaps": "./bin/palari scope-overlaps",
            "ruleset": "./bin/palari github ruleset-command --repo OWNER/REPO",
        },
    }


class ConsoleHandler(SimpleHTTPRequestHandler):
    root: Path

    def translate_path(self, path: str) -> str:
        parsed = urllib.parse.urlparse(path)
        clean = parsed.path.lstrip("/") or "index.html"
        target = (STATIC_DIR / clean).resolve()
        if not str(target).startswith(str(STATIC_DIR.resolve())):
            return str(STATIC_DIR / "index.html")
        if target.is_dir():
            target = target / "index.html"
        return str(target)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/snapshot":
            self.send_json(snapshot(self.root))
            return
        super().do_GET()

    def send_json(self, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: Any) -> None:
        return


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the optional Palari Console web dashboard.")
    parser.add_argument("--root", default=os.environ.get("PALARI_ROOT", os.getcwd()))
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--check", action="store_true", help="Print a dashboard snapshot and exit.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if args.check:
        print(json.dumps(snapshot(root), indent=2))
        return 0

    ConsoleHandler.root = root
    server = ThreadingHTTPServer((args.host, args.port), ConsoleHandler)
    print(f"Palari Console: http://{args.host}:{args.port}")
    print(f"Repo root: {root}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nPalari Console stopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
