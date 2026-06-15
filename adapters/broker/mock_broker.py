#!/usr/bin/env python3
"""Mock broker evidence capture.

This adapter records observed-command evidence for a ticket while keeping the
broker side-effect boundary explicit: real side effects are disabled, no
credentials are loaded, and obvious dangerous commands are refused before
execution.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import tarfile
import tempfile
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

SANDBOX_SHELL_FORBIDDEN_TOKENS = (
    "$",
    "`",
    "|",
    "&",
    ";",
    "<",
    "\n",
)

SANDBOX_PRINTF_REDIRECT = re.compile(
    r"^\s*printf\s+(?P<quote>['\"])(?P<body>[^'\"]*)(?P=quote)\s*(?P<redir>>>?)\s*(?P<target>[A-Za-z0-9._/-]+)\s*$"
)

SECRET_ENV_EXACT = {
    "GITHUB_TOKEN",
    "OPENAI_API_KEY",
    "ANTHROPIC_API_KEY",
}

SECRET_ENV_SUFFIXES = (
    "_TOKEN",
    "_KEY",
    "_SECRET",
)


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_json(data: dict[str, Any]) -> str:
    encoded = json.dumps(data, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return sha256_bytes(encoded)


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


def find_ticket_file(root: Path, ticket: str) -> Path | None:
    for rel_dir in ("tickets/open", "tickets/closed", "tickets/proposed"):
        for path in sorted((root / rel_dir).glob(f"{ticket}-*.md")):
            return path
    return None


def ticket_frontmatter(root: Path, ticket: str) -> dict[str, Any]:
    path = find_ticket_file(root, ticket)
    if path is None:
        return {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return {}
    data: dict[str, Any] = {}
    key = ""
    for line in lines[1:]:
        if line == "---":
            break
        if line.startswith("  - ") and key:
            data.setdefault(key, []).append(line[4:].strip().strip('"'))
            continue
        if ":" not in line or line.startswith(" "):
            continue
        raw_key, raw_value = line.split(":", 1)
        key = raw_key.strip()
        value = raw_value.strip()
        if value:
            data[key] = value.strip('"')
        else:
            data[key] = []
    return data


def normalize_repo_path(path: str) -> tuple[str, str]:
    clean = path.strip().strip('"').replace("\\", "/")
    if not clean:
        return "", "resource path is empty"
    if clean.startswith("/") or re.match(r"^[A-Za-z]:", clean):
        return "", "resource path must be relative to the repository"
    parts: list[str] = []
    for part in clean.split("/"):
        if part in {"", "."}:
            continue
        if part == "..":
            if not parts:
                return "", "resource path escapes the repository"
            parts.pop()
            continue
        parts.append(part)
    return "/".join(parts) if parts else ".", ""


def path_matches(path: str, pattern: str) -> bool:
    clean_path, path_error = normalize_repo_path(path)
    if path_error:
        return False
    clean_pattern = pattern.removeprefix("./").strip('"')
    return fnmatch.fnmatchcase(clean_path, clean_pattern)


def changed_path_violations(paths: list[str], meta: dict[str, Any]) -> tuple[list[str], list[str]]:
    allowed = [str(item) for item in meta.get("allowed_paths", []) if str(item)]
    forbidden = [str(item) for item in meta.get("forbidden_paths", []) if str(item)]
    violations: list[str] = []
    outside_scope: list[str] = []
    for raw_path in paths:
        path, path_error = normalize_repo_path(raw_path)
        if path_error:
            outside_scope.append(raw_path)
            continue
        if any(path_matches(path, pattern) for pattern in forbidden):
            violations.append(path)
            continue
        if allowed and not any(path_matches(path, pattern) for pattern in allowed):
            outside_scope.append(path)
    return sorted(violations), sorted(outside_scope)


def scrubbed_environment(*, home: Path | None = None, tmp: Path | None = None) -> dict[str, str]:
    clean: dict[str, str] = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "LANG": os.environ.get("LANG", "C.UTF-8"),
    }
    if home is not None:
        clean["HOME"] = str(home)
    if tmp is not None:
        clean["TMPDIR"] = str(tmp)
    return clean


def create_repo_copy(root: Path) -> tuple[Path, Path]:
    temp_root = Path(tempfile.mkdtemp(prefix="palari-broker-sandbox-"))
    sandbox = temp_root / "repo"
    sandbox.mkdir(parents=True, exist_ok=True)
    archive = subprocess.run(
        ["git", "-C", str(root), "archive", "--format=tar", "HEAD"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    with tarfile.open(fileobj=io.BytesIO(archive.stdout), mode="r:") as tar:
        tar.extractall(sandbox)
    subprocess.run(["git", "-C", str(sandbox), "init", "-b", "sandbox"], stdout=subprocess.DEVNULL, check=True)
    subprocess.run(["git", "-C", str(sandbox), "config", "user.email", "palari-broker-sandbox@example.invalid"], check=True)
    subprocess.run(["git", "-C", str(sandbox), "config", "user.name", "Palari Broker Sandbox"], check=True)
    subprocess.run(["git", "-C", str(sandbox), "add", "."], check=True)
    subprocess.run(
        ["git", "-C", str(sandbox), "commit", "-m", "broker sandbox baseline"],
        stdout=subprocess.DEVNULL,
        check=True,
    )
    return temp_root, sandbox


def sandbox_patch(sandbox: Path) -> bytes:
    subprocess.run(["git", "-C", str(sandbox), "add", "-N", "."], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    result = subprocess.run(
        ["git", "-C", str(sandbox), "diff", "--binary"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.stdout


def refusal_reason(command: list[str]) -> str:
    joined = " ".join(command).lower()
    for snippet in DANGEROUS_SNIPPETS:
        if snippet in joined:
            return f"refused dangerous command pattern: {snippet.strip()}"
    return ""


def sandbox_command_refusal(command: list[str]) -> str:
    reason = refusal_reason(command)
    if reason:
        return reason
    if len(command) != 3 or command[0] != "sh" or command[1] != "-c":
        return "sandbox command refused: only `sh -c` simple printf redirection is supported"

    script = command[2]
    if any(token in script for token in SANDBOX_SHELL_FORBIDDEN_TOKENS):
        return "sandbox command refused: shell expansion, pipelines, redirects-from, and command chaining are not supported"
    match = SANDBOX_PRINTF_REDIRECT.match(script)
    if not match:
        return "sandbox command refused: only simple `printf ... > relative-repo-path` writes are supported"
    _, path_error = normalize_repo_path(match.group("target"))
    if path_error:
        return f"sandbox command refused: {path_error}"
    return ""


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def action_request(root: Path, ticket: str, command: list[str], out: Path) -> dict[str, Any]:
    meta = ticket_frontmatter(root, ticket)
    request_id = f"BRK-REQ-{out.name}"
    risk = str(meta.get("risk") or "R0")
    return {
        "schema_version": "broker-action-request-v1",
        "request_id": request_id,
        "actor": "palari-local-broker",
        "ticket": ticket,
        "workflow": str(meta.get("workflow") or ""),
        "risk": risk,
        "tool": command[0] if command else "",
        "action": "execute_command",
        "resource": ".",
        "side_effect_class": "local_process_observation",
        "requires_human": risk in {"R3", "R4", "R5"},
        "requires_policy": False,
        "allowed_by": ["mock_only_observation", "ticket_exists"],
        "forbidden_if": [
            "credential_required",
            "network_required",
            "resource_outside_ticket_scope",
            "forbidden_path",
            "real_side_effect_requested",
        ],
    }


def broker_result(
    request: dict[str, Any],
    *,
    reason: str,
    timed_out: bool,
    exit_code: int,
    stdout: bytes,
    stderr: bytes,
    changed_paths: list[str],
    observed_at: str,
) -> dict[str, Any]:
    if reason:
        status = "denied"
        decision_reason = "dangerous_command_refused"
        decision_reasons = [reason]
    elif timed_out:
        status = "failed"
        decision_reason = "command_timeout"
        decision_reasons = ["mock broker command timed out"]
    elif exit_code != 0:
        status = "failed"
        decision_reason = "command_failed"
        decision_reasons = [f"command exited {exit_code}"]
    else:
        status = "observed"
        decision_reason = "mock_broker_observed_command"
        decision_reasons = ["mock broker observed command"]
    output_material = stdout + b"\n" + stderr + b"\n" + "\n".join(changed_paths).encode("utf-8")
    return {
        "schema_version": "broker-result-v1",
        "request_id": request["request_id"],
        "status": status,
        "decision_reason": decision_reason,
        "decision_reasons": decision_reasons,
        "observed_at": observed_at,
        "input_hash": sha256_json(request),
        "output_hash": sha256_bytes(output_material),
        "changed_resources": changed_paths,
        "side_effects_enabled": False,
        "signed_by": "broker-mock",
    }


def run_command(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    out = Path(args.out).resolve()
    command = list(args.command)
    out.mkdir(parents=True, exist_ok=True)
    run_id = out.name
    started_at = now()
    request = action_request(root, args.ticket, command, out)

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
    ended_at = now()
    result_record = broker_result(
        request,
        reason=reason,
        timed_out=timed_out,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        changed_paths=changed_paths,
        observed_at=ended_at,
    )

    (out / "stdout.txt").write_bytes(stdout)
    (out / "stderr.txt").write_bytes(stderr)
    (out / "changed_paths.txt").write_text("\n".join(changed_paths) + ("\n" if changed_paths else ""), encoding="utf-8")
    command_record = {
        "schema_version": "1",
        "ticket": args.ticket,
        "created_at": started_at,
        "mode": "mock",
        "side_effects_enabled": False,
        "credentials_available_to_agents": False,
        "network_or_hosted_api_access": False,
        "cwd": str(root),
        "command": command,
    }
    write_json(out / "request.json", request)
    write_json(out / "result.json", result_record)
    write_json(out / "command.json", command_record)
    summary = {
        **command_record,
        "schema_version": "broker-observation-v1",
        "run_id": run_id,
        "broker_mode": "mock",
        "boundary_type": "observed_only",
        "working_directory": str(root),
        "started_at": started_at,
        "ended_at": ended_at,
        "request_id": request["request_id"],
        "action_request": request,
        "broker_result": result_record,
        "status": result_record["status"],
        "decision": result_record["status"],
        "decision_reason": result_record["decision_reason"],
        "decision_reasons": result_record["decision_reasons"],
        "executed": executed,
        "refused": bool(reason),
        "refusal_reason": reason,
        "timed_out": timed_out,
        "exit_code": exit_code,
        "stdout_sha256": sha256_bytes(stdout),
        "stderr_sha256": sha256_bytes(stderr),
        "changed_paths": changed_paths,
        "changed_resources": changed_paths,
        "forbidden_path_changes": [],
        "signed_by": result_record["signed_by"],
        "input_hash": result_record["input_hash"],
        "output_hash": result_record["output_hash"],
        "artifacts": {
            "command": "command.json",
            "request": "request.json",
            "result": "result.json",
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


def run_sandbox(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    out = Path(args.out).resolve()
    command = list(args.command)
    out.mkdir(parents=True, exist_ok=True)
    run_id = out.name
    started_at = now()
    meta = ticket_frontmatter(root, args.ticket)
    request = action_request(root, args.ticket, command, out)
    request["side_effect_class"] = "repo_file_write"
    request["allowed_by"] = ["local_sandbox_repo_copy", "ticket_scope"]

    reason = sandbox_command_refusal(command)
    stdout = b""
    stderr = b""
    exit_code = 126 if reason else 0
    broker_exit_code = exit_code
    timed_out = False
    executed = False
    changed_paths: list[str] = []
    forbidden_changes: list[str] = []
    outside_scope_changes: list[str] = []
    patch = b""
    temp_root: Path | None = None
    sandbox: Path | None = None

    try:
        if not reason:
            temp_root, sandbox = create_repo_copy(root)
            sandbox_home = temp_root / "home"
            sandbox_tmp = temp_root / "tmp"
            sandbox_home.mkdir(parents=True, exist_ok=True)
            sandbox_tmp.mkdir(parents=True, exist_ok=True)
            executed = True
            try:
                result = subprocess.run(
                    command,
                    cwd=sandbox,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=30,
                    check=False,
                    env=scrubbed_environment(home=sandbox_home, tmp=sandbox_tmp),
                )
                stdout = result.stdout
                stderr = result.stderr
                exit_code = int(result.returncode)
            except subprocess.TimeoutExpired as exc:
                stdout = exc.stdout or b""
                stderr = (exc.stderr or b"") + b"\nlocal sandbox broker timeout after 30 seconds\n"
                exit_code = 124
                timed_out = True
            changed_paths = sorted(git_status(sandbox))
            forbidden_changes, outside_scope_changes = changed_path_violations(changed_paths, meta)
            patch = sandbox_patch(sandbox)
        forbidden_path_changes = sorted(set(forbidden_changes + outside_scope_changes))
        ended_at = now()

        if reason:
            decision = "denied"
            decision_reason = "sandbox_command_refused"
            decision_reasons = [reason]
            broker_exit_code = 126
        elif forbidden_path_changes:
            decision = "denied_or_violation"
            decision_reason = "sandbox_scope_violation"
            decision_reasons = []
            for path in forbidden_changes:
                decision_reasons.append(f"forbidden path changed: {path}")
            for path in outside_scope_changes:
                decision_reasons.append(f"path outside ticket scope changed: {path}")
            broker_exit_code = 1
        elif timed_out:
            decision = "failed"
            decision_reason = "command_timeout"
            decision_reasons = ["local sandbox command timed out"]
            broker_exit_code = exit_code
        elif exit_code != 0:
            decision = "failed"
            decision_reason = "command_failed"
            decision_reasons = [f"command exited {exit_code}"]
            broker_exit_code = exit_code
        else:
            decision = "observed_allowed"
            decision_reason = "sandbox_changes_within_ticket_scope"
            decision_reasons = ["local sandbox changed only ticket-allowed paths"]
            broker_exit_code = 0

        result_status = "observed" if decision == "observed_allowed" else "failed" if decision == "failed" else "denied"
        output_material = stdout + b"\n" + stderr + b"\n" + "\n".join(changed_paths).encode("utf-8")
        result_record = {
            "schema_version": "broker-result-v1",
            "request_id": request["request_id"],
            "status": result_status,
            "decision_reason": decision_reason,
            "decision_reasons": decision_reasons,
            "observed_at": ended_at,
            "input_hash": sha256_json(request),
            "output_hash": sha256_bytes(output_material),
            "changed_resources": changed_paths,
            "side_effects_enabled": False,
            "signed_by": "broker-sandbox",
        }
        command_record = {
            "schema_version": "1",
            "ticket": args.ticket,
            "created_at": started_at,
            "mode": "sandbox",
            "side_effects_enabled": False,
            "credentials_available_to_agents": False,
            "network_or_hosted_api_access": False,
            "network_isolation_enforced": False,
            "sandbox_command_policy": "simple_printf_redirect_only",
            "cwd": str(sandbox or root),
            "command": command,
        }

        (out / "stdout.txt").write_bytes(stdout)
        (out / "stderr.txt").write_bytes(stderr)
        (out / "changed_paths.txt").write_text("\n".join(changed_paths) + ("\n" if changed_paths else ""), encoding="utf-8")
        (out / "patch.diff").write_bytes(patch)
        write_json(out / "request.json", request)
        write_json(out / "result.json", result_record)
        write_json(out / "command.json", command_record)
        summary = {
            **command_record,
            "schema_version": "broker-observation-v1",
            "run_id": run_id,
            "broker_mode": "sandbox",
            "boundary_type": "local_sandbox_repo_copy",
            "sandbox_command_policy": "simple_printf_redirect_only",
            "working_directory": str(sandbox or root),
            "started_at": started_at,
            "ended_at": ended_at,
            "request_id": request["request_id"],
            "action_request": request,
            "broker_result": result_record,
            "status": result_record["status"],
            "decision": decision,
            "decision_reason": decision_reason,
            "decision_reasons": decision_reasons,
            "executed": executed,
            "refused": bool(reason),
            "refusal_reason": reason,
            "timed_out": timed_out,
            "exit_code": exit_code,
            "broker_exit_code": broker_exit_code,
            "stdout_sha256": sha256_bytes(stdout),
            "stderr_sha256": sha256_bytes(stderr),
            "changed_paths": changed_paths,
            "changed_resources": changed_paths,
            "forbidden_path_changes": forbidden_path_changes,
            "outside_scope_changes": outside_scope_changes,
            "sandbox_real_repo_mutated": False,
            "sandbox_retained": False,
            "signed_by": result_record["signed_by"],
            "input_hash": result_record["input_hash"],
            "output_hash": result_record["output_hash"],
            "artifacts": {
                "command": "command.json",
                "request": "request.json",
                "result": "result.json",
                "stdout": "stdout.txt",
                "stderr": "stderr.txt",
                "changed_paths": "changed_paths.txt",
                "patch": "patch.diff",
            },
        }
        write_json(out / "summary.json", summary)

        rel = out.relative_to(root)
        print(f"broker sandbox: {args.ticket}")
        print(f"decision: {decision}")
        print(f"exit_code: {exit_code}")
        print(f"broker_exit_code: {broker_exit_code}")
        print("side_effects_enabled: false")
        print("boundary_type: local_sandbox_repo_copy")
        if reason:
            print(f"refused: {reason}")
        if forbidden_path_changes:
            print(f"forbidden_path_changes: {len(forbidden_path_changes)}")
        print(f"evidence: {rel}")
        return broker_exit_code
    finally:
        if temp_root is not None:
            shutil.rmtree(temp_root, ignore_errors=True)


def check_permission(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    meta = ticket_frontmatter(root, args.ticket)
    if not meta:
        raise SystemExit(f"ticket not found: {args.ticket}")
    risk = str(meta.get("risk") or "R0")
    normalized_resource, resource_error = normalize_repo_path(args.resource)
    forbidden_changes, outside_scope_changes = changed_path_violations([args.resource], meta)
    allowed = not forbidden_changes and not outside_scope_changes
    reasons: list[str] = []
    if resource_error:
        reasons.append(resource_error)
    if forbidden_changes:
        reasons.append("resource matches ticket forbidden paths")
    if outside_scope_changes:
        reasons.append("resource is outside ticket allowed paths")
    if allowed:
        reasons.append("resource is within ticket allowed paths")
    data = {
        "allowed": allowed,
        "reasons": reasons,
        "risk": risk,
        "requires_human": risk in {"R3", "R4", "R5"},
        "requires_policy": False,
        "side_effects_enabled": False,
        "would_execute": False,
        "tool": args.tool,
        "action": args.action,
        "resource": args.resource,
        "normalized_resource": normalized_resource or args.resource,
        "boundary_type": "permission_check_only",
    }
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
        return 0
    print("Broker permission check")
    print(f"allowed: {str(allowed).lower()}")
    print(f"risk: {risk}")
    print(f"requires_human: {str(data['requires_human']).lower()}")
    print("side_effects_enabled: false")
    print("would_execute: false")
    print("reasons:")
    for reason in reasons:
        print(f"- {reason}")
    return 0


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

    sandbox = sub.add_parser("sandbox")
    sandbox.add_argument("--root", required=True)
    sandbox.add_argument("--ticket", required=True)
    sandbox.add_argument("--out", required=True)
    sandbox.add_argument("command", nargs=argparse.REMAINDER)

    evidence = sub.add_parser("evidence")
    evidence.add_argument("--root", required=True)
    evidence.add_argument("--ticket", required=True)
    evidence.add_argument("--evidence-dir", required=True)
    evidence.add_argument("--json", action="store_true")

    check = sub.add_parser("check")
    check.add_argument("--root", required=True)
    check.add_argument("--ticket", required=True)
    check.add_argument("--tool", required=True)
    check.add_argument("--action", required=True)
    check.add_argument("--resource", required=True)
    check.add_argument("--json", action="store_true")

    args = parser.parse_args()
    if args.command_name in {"run", "sandbox"}:
        if args.command and args.command[0] == "--":
            args.command = args.command[1:]
        if not args.command:
            raise SystemExit(f"error: broker {args.command_name} requires a command")
        if args.command_name == "sandbox":
            return run_sandbox(args)
        return run_command(args)
    if args.command_name == "check":
        return check_permission(args)
    return list_evidence(args)


if __name__ == "__main__":
    raise SystemExit(main())
