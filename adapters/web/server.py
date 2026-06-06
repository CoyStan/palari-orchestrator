#!/usr/bin/env python3
"""Palari Console: optional local web dashboard for Palari Orchestrator."""

from __future__ import annotations

import argparse
import ipaddress
import json
import os
import subprocess
import sys
import threading
import time
import urllib.parse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
STATIC_DIR = HERE / "static"
SNAPSHOT_CACHE_TTL = 2.0
SNAPSHOT_CACHE_LOCK = threading.Lock()
SNAPSHOT_CACHE: dict[str, Any] = {
    "root": None,
    "at": 0.0,
    "payload": None,
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


def snapshot(root: Path) -> dict[str, Any]:
    cli = root / "bin" / "palari"
    result = run(root, [str(cli), "snapshot", "--json"], timeout=10)
    if not result["ok"]:
        raise RuntimeError(result["stderr"] or result["stdout"] or "palari snapshot failed")
    try:
        return json.loads(result["stdout"])
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"palari snapshot returned invalid JSON: {exc}") from exc


def cached_snapshot(root: Path) -> dict[str, Any]:
    cache_key = str(root)
    now = time.monotonic()
    with SNAPSHOT_CACHE_LOCK:
        if (
            SNAPSHOT_CACHE["root"] == cache_key
            and SNAPSHOT_CACHE["payload"] is not None
            and now - float(SNAPSHOT_CACHE["at"]) < SNAPSHOT_CACHE_TTL
        ):
            return SNAPSHOT_CACHE["payload"]

        payload = snapshot(root)
        SNAPSHOT_CACHE["root"] = cache_key
        SNAPSHOT_CACHE["at"] = time.monotonic()
        SNAPSHOT_CACHE["payload"] = payload
        return payload


class ConsoleHandler(SimpleHTTPRequestHandler):
    root: Path

    def translate_path(self, path: str) -> str:
        parsed = urllib.parse.urlparse(path)
        clean = parsed.path.lstrip("/") or "index.html"
        static_root = STATIC_DIR.resolve()
        target = (STATIC_DIR / clean).resolve()
        try:
            target.relative_to(static_root)
        except ValueError:
            return str(static_root / "index.html")
        if target.is_dir():
            target = target / "index.html"
        return str(target)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/snapshot":
            try:
                query = urllib.parse.parse_qs(parsed.query)
                if query.get("fresh") == ["1"]:
                    self.send_json(snapshot(self.root))
                else:
                    self.send_json(cached_snapshot(self.root))
            except RuntimeError as exc:
                self.send_error(500, str(exc))
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
        try:
            print(json.dumps(snapshot(root), indent=2))
            return 0
        except RuntimeError as exc:
            print(f"palari web check failed: {exc}", file=sys.stderr)
            return 1

    if not is_loopback_host(args.host):
        print(
            "warning: palari web uses Python's local http.server; bind to loopback for local monitoring.",
            file=sys.stderr,
        )

    ConsoleHandler.root = root
    server = ThreadingHTTPServer((args.host, args.port), ConsoleHandler)
    print(f"Palari Console: http://{args.host}:{args.port}")
    print(f"Repo root: {root}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nPalari Console stopped.")
    return 0


def is_loopback_host(host: str) -> bool:
    if host == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


if __name__ == "__main__":
    raise SystemExit(main())
