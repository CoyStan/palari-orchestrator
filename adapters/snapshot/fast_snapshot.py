#!/usr/bin/env python3
"""Palari fast snapshot engine.

A dependency-free read model for operator state. It parses tickets, roles,
proposals, decisions, reports, and evidence ONCE, builds indexes, and emits
the same fast-mode snapshot JSON shape as the legacy Bash path, in a few
tens of milliseconds instead of seconds.

Design rules (the contract with bin/palari):
  - No PyYAML, no third-party imports, stdlib only.
  - At most one subprocess: `git status` (skippable via PALARI_FAST_GIT=0).
  - No role lint, no report lint, no memory indexing, no Forgegate import.
    Those are diagnostics and belong to `snapshot --json --full`, `lint`,
    and `doctor` on the slow path.
  - Additive keys only: `snapshot_engine` and `evidence.executor_evidence`
    are new; everything else mirrors the Bash fast snapshot.

The web server imports `snapshot_dict()` directly so dashboard refreshes do
not spawn a shell at all.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

PLANNING_ADAPTER_DIR = Path(__file__).resolve().parents[1] / "planning"
if str(PLANNING_ADAPTER_DIR) not in sys.path:
    sys.path.insert(0, str(PLANNING_ADAPTER_DIR))
try:
    import company_os_snapshot
except Exception:  # pragma: no cover - fast snapshot degrades below.
    company_os_snapshot = None

HYGIENE_DEFAULT_GENERATED = [
    "__pycache__/**",
    "**/__pycache__/**",
    "*.pyc",
    "**/*.pyc",
    ".DS_Store",
    ".palari/**",
    ".expo/**",
    ".metro/**",
]

ACTIVE_STATUSES = ["open", "claimed", "blocked", "needs-human", "in-review", "reopened"]
INBOX_PRIORITY = [
    "human-gate",
    "blocked",
    "review-needed",
    "evidence-needed",
    "can-continue",
    "watch",
    "monitor",
]
INBOX_LABELS = {
    "human-gate": "Needs human decision",
    "blocked": "Blocked",
    "review-needed": "Review needed",
    "evidence-needed": "Evidence needed",
    "can-continue": "Can continue",
    "watch": "Watch",
    "monitor": "Monitor",
}


# ---------------------------------------------------------------- parsing

def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def parse_frontmatter(path: Path) -> dict:
    """Scalars -> str, lists -> list[str]. Tolerant, mirrors the Bash parser."""
    out: dict = {}
    text = read_text(path)
    if not text.startswith("---"):
        return out
    body = text.split("\n")
    current_list = None
    for line in body[1:]:
        if line.strip() == "---":
            break
        if re.match(r"^\s+-\s+", line) and current_list is not None:
            out[current_list].append(strip_quotes(re.sub(r"^\s+-\s+", "", line)))
            continue
        match = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", line)
        if not match:
            continue
        key, value = match.group(1), match.group(2)
        value = re.sub(r"\s+#.*$", "", value).strip()
        if value == "":
            out[key] = []
            current_list = key
        else:
            out[key] = strip_quotes(value)
            current_list = None
    # Keys that ended as empty lists but are conceptually scalars stay [].
    return out


def parse_config(root: Path) -> dict:
    """Flat scalars, lists, one-level nesting, and simple nested maps."""
    flat: dict = {}
    nested: dict = {}
    maps: dict = {}
    lists: dict = {}
    section = None
    current_map = None
    current_list = None
    for raw in read_text(root / "palari.config.yaml").split("\n"):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        indented = indent > 0 or raw.startswith("\t")
        line = raw.strip()
        if not indented:
            current_map = None
            current_list = None
            match = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", line)
            if not match:
                continue
            key, value = match.group(1), re.sub(r"\s+#.*$", "", match.group(2)).strip()
            if value == "":
                section = key
                flat.setdefault(key, "")
                lists[key] = []
                current_list = key
            else:
                section = None
                flat[key] = strip_quotes(value)
        else:
            if line.startswith("- ") and current_list and not current_map:
                lists[current_list].append(strip_quotes(line[2:]))
                continue
            match = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", line)
            if match and section and current_map and indent >= 4:
                value = re.sub(r"\s+#.*$", "", match.group(2)).strip()
                maps.setdefault(section, {}).setdefault(current_map, {})[match.group(1)] = strip_quotes(value)
                continue
            if match and section and indent <= 2:
                value = re.sub(r"\s+#.*$", "", match.group(2)).strip()
                nested.setdefault(section, {})[match.group(1)] = strip_quotes(value)
                current_map = match.group(1) if value == "" else None
                current_list = None
    return {"flat": flat, "nested": nested, "maps": maps, "lists": lists}


def cfg(config: dict, key: str, default: str = "") -> str:
    value = config["flat"].get(key, "")
    return value if value != "" else default


def cfg_nested(config: dict, section: str, key: str, default: str = "") -> str:
    value = config["nested"].get(section, {}).get(key, "")
    return value if value != "" else default


def cfg_nested_map(config: dict, section: str, map_key: str, key: str, default: str = "") -> str:
    value = config.get("maps", {}).get(section, {}).get(map_key, {}).get(key, "")
    return value if value != "" else default


def approval_quorum_for_risk(config: dict, risk: str) -> int:
    raw = cfg_nested_map(config, "governance", "required_human_approvals", risk, "")
    if raw == "":
        raw = cfg_nested(config, "governance", f"required_human_approvals_{risk}", "")
    if raw == "" and risk == "R5" and cfg_nested(config, "governance", "r5_requires_dual_human", "false") == "true":
        raw = "2"
    if raw == "":
        raw = "1" if risk == "R5" else "0"
    try:
        return max(0, int(raw))
    except ValueError:
        return 1 if risk == "R5" else 0


def human_placeholder(config: dict, index: int) -> str:
    default_human = cfg_nested(config, "governance", "default_human_approver", "")
    if index == 1 and default_human:
        return default_human
    if index == 1:
        return "HUMAN-ONE"
    if index == 2:
        return "HUMAN-TWO"
    if index == 3:
        return "HUMAN-THREE"
    return f"HUMAN-{index}"


def accept_command_for_ticket(fm: dict, ticket_id: str, config: dict, by: str, prefix: str) -> str:
    quorum = approval_quorum_for_risk(config, scalar(fm, "risk"))
    if quorum <= 0:
        return f"{prefix} accept {ticket_id} --by {by}"
    command = f"{prefix} accept {ticket_id} --by {human_placeholder(config, 1)}"
    for index in range(2, quorum + 1):
        command += f" --co-by {human_placeholder(config, index)}"
    return command


def glob_to_regex(pattern: str) -> re.Pattern:
    out = []
    i = 0
    while i < len(pattern):
        ch = pattern[i]
        if ch == "*":
            if pattern[i : i + 2] == "**":
                out.append(".*")
                i += 2
                if i < len(pattern) and pattern[i] == "/":
                    i += 1
                continue
            out.append("[^/]*")
        elif ch == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(ch))
        i += 1
    return re.compile("^" + "".join(out) + "$")


# ---------------------------------------------------------------- indexes

def md_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(
        p for p in directory.iterdir() if p.suffix == ".md" and p.name != "README.md"
    )


def build_reports_index(root: Path, reports_dir: str) -> dict:
    index: dict = {}
    rdir = root / reports_dir
    if not rdir.is_dir():
        return index
    for path in rdir.iterdir():
        if not path.is_file() or not path.name.endswith(".md"):
            continue
        match = re.match(r"^([A-Z][A-Z0-9]{2,}-\d{4})-(.+)\.md$", path.name)
        if not match:
            continue
        ticket_id, kind = match.group(1), match.group(2)
        entry = index.setdefault(
            ticket_id, {"technical": False, "reviewer": False, "human": False, "custom": []}
        )
        if kind == "technical-report":
            entry["technical"] = True
        elif kind == "reviewer-note":
            entry["reviewer"] = True
        elif kind.endswith("-note") or kind.endswith("-report"):
            entry["custom"].append(kind)
    hdir = rdir / "human"
    if hdir.is_dir():
        for path in hdir.iterdir():
            match = re.match(r"^([A-Z][A-Z0-9]{2,}-\d{4})-human-report\.md$", path.name)
            if match:
                index.setdefault(
                    match.group(1),
                    {"technical": False, "reviewer": False, "human": False, "custom": []},
                )["human"] = True
    return index


def build_evidence_index(root: Path, evidence_dir: str) -> dict:
    index: dict = {}
    edir = root / evidence_dir
    if not edir.is_dir():
        return index
    for tdir in edir.iterdir():
        if not tdir.is_dir():
            continue
        files = sorted(p.name for p in tdir.iterdir() if p.is_file())
        entry = {
            "path": f"{evidence_dir}/{tdir.name}",
            "files": [
                n
                for n in ("verification.log", "junit.xml", "palari.sarif", "manifest.json")
                if n in files
            ],
            "has_log": "verification.log" in files,
            "has_junit": "junit.xml" in files,
            "has_sarif": "palari.sarif" in files,
            "has_manifest": "manifest.json" in files,
            "file_count": len(files),
        }
        executor_root = tdir / "executor"
        executor_evidence = []
        if executor_root.is_dir():
            for xdir in sorted(executor_root.iterdir()):
                if not xdir.is_dir():
                    continue
                xfiles = sorted(p.name for p in xdir.iterdir() if p.is_file())

                def read_exit(name: str):
                    raw = read_text(xdir / name).strip()
                    return int(raw) if raw.lstrip("-").isdigit() else None

                executor_evidence.append(
                    {
                        "executor": xdir.name,
                        "path": f"{evidence_dir}/{tdir.name}/executor/{xdir.name}",
                        "files": xfiles,
                        "run_exit": read_exit("run.exit"),
                        "scope_check_exit": read_exit("scope-check.exit"),
                        "ci_exit": read_exit("ci.exit"),
                        "model": read_text(xdir / "model.txt").strip() or None,
                    }
                )
        entry["executor_evidence"] = executor_evidence
        index[tdir.name] = entry
    return index


# ---------------------------------------------------------------- tickets

def now_utc() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def parse_utc(value: str):
    try:
        return time.mktime(time.strptime(value, "%Y-%m-%dT%H:%M:%SZ")) - time.timezone
    except (ValueError, OverflowError):
        return None


def lease_info(fm: dict) -> dict:
    expires = fm.get("claim_expires_at", "") or ""
    if isinstance(expires, list):
        expires = ""
    if not expires:
        return {"status": "none", "expires_at": "", "seconds_remaining": 0}
    expiry = parse_utc(expires)
    if expiry is None:
        return {"status": "unknown", "expires_at": expires, "seconds_remaining": 0}
    remaining = int(expiry - time.time())
    return {
        "status": "active" if remaining > 0 else "expired",
        "expires_at": expires,
        "seconds_remaining": max(remaining, 0),
    }


def scalar(fm: dict, key: str, default: str = "") -> str:
    value = fm.get(key, default)
    if isinstance(value, list):
        return default
    return value or default


def listval(fm: dict, key: str) -> list:
    value = fm.get(key, [])
    return value if isinstance(value, list) else []


def next_action(
    fm: dict,
    ticket_id: str,
    status: str,
    default_branch: str,
    evidence: dict,
    reports: dict,
    config: dict,
) -> dict:
    target = scalar(fm, "target_branch") or default_branch
    has_evidence = bool(
        evidence
        and evidence.get("has_log")
        and evidence.get("has_junit")
        and evidence.get("has_manifest")
    )
    requires_review = scalar(fm, "requires_review") == "true" or scalar(fm, "risk") in (
        "R2",
        "R3",
        "R4",
    )
    reports_ready = bool(
        reports
        and reports.get("technical")
        and (reports.get("reviewer") or not requires_review)
    )

    def action(label, detail, command, actor, severity):
        return {
            "label": label,
            "detail": detail,
            "command": command,
            "actor": actor,
            "severity": severity,
        }

    if status == "accepted":
        by, at = scalar(fm, "accepted_by"), scalar(fm, "accepted_at")
        detail = "Closed on the repository source of truth."
        if by or at:
            detail = f"Accepted by {by or 'unknown'}" + (f" at {at}" if at else "") + "."
        return action("Accepted", detail, "", "none", "clear")
    if status == "open":
        return action(
            "Claim and isolate",
            "Assign an owner and create the ticket worktree before implementation starts.",
            f"./bin/palari ticket claim {ticket_id} YOUR-NAME && ./bin/palari worktree {ticket_id}",
            "orchestrator",
            "next",
        )
    if status == "claimed":
        if lease_info(fm)["status"] == "expired":
            return action(
                "Renew or release claim",
                "The current claim lease is expired, so ownership is unclear.",
                f"./bin/palari ticket heartbeat {ticket_id}",
                "owner",
                "watch",
            )
        if has_evidence and reports_ready:
            return action(
                "Move to review",
                "Evidence and required reports are present; hand the ticket to a fresh reviewer.",
                f"./bin/palari ticket ready {ticket_id}",
                "specialist",
                "next",
            )
        return action(
            "Finish evidence",
            "Complete scoped work, specialist reporting, and CI evidence before review.",
            f"./bin/palari worktree {ticket_id} && ./bin/palari packet {ticket_id} specialist && ./bin/palari ci {ticket_id} --base {target}",
            "specialist",
            "next",
        )
    if status == "in-review":
        if not has_evidence:
            return action(
                "Create evidence",
                "Review cannot complete until the standard evidence bundle exists.",
                f"./bin/palari ci {ticket_id} --base {target}",
                "specialist",
                "blocked",
            )
        if not reports_ready:
            return action(
                "Complete review reports",
                "A reviewer or required custom/human report is missing.",
                f"./bin/palari packet {ticket_id} reviewer",
                "reviewer",
                "blocked",
            )
        return action(
            "Accept or reopen",
            "A human or authorized acceptor should accept the ticket or send it back.",
            accept_command_for_ticket(fm, ticket_id, config, "founder", "./bin/palari"),
            "human",
            "waiting",
        )
    if status == "blocked":
        return action(
            "Resolve blocker",
            "Inspect the ticket and write a handoff note so the block is visible.",
            f"./bin/palari packet {ticket_id} human",
            "orchestrator",
            "blocked",
        )
    if status == "needs-human":
        return action(
            "Human decision required",
            "A person needs to resolve product direction, authority, or acceptance criteria.",
            f"./bin/palari packet {ticket_id} human",
            "human",
            "blocked",
        )
    if status == "reopened":
        return action(
            "Continue revised work",
            "Claim the ticket again and continue from the updated reviewer guidance.",
            f"./bin/palari ticket claim {ticket_id} YOUR-NAME && ./bin/palari packet {ticket_id} specialist",
            "specialist",
            "next",
        )
    return action(
        "Inspect ticket state",
        "This ticket has an unexpected status.",
        f"./bin/palari lint {ticket_id}",
        "orchestrator",
        "watch",
    )


def inbox_category(status: str, actor: str, severity: str, label: str) -> str:
    if actor == "human" or status == "needs-human":
        return "human-gate"
    if severity == "blocked" or status == "blocked":
        return "blocked"
    if actor == "reviewer":
        return "review-needed"
    if label in ("Finish evidence", "Create evidence"):
        return "evidence-needed"
    if severity == "next":
        return "can-continue"
    if severity == "watch":
        return "watch"
    return "monitor"


def company_card(card_id: str, label_text: str, value: str, status: str, detail: str) -> dict:
    return {
        "id": card_id,
        "label": label_text,
        "value": value,
        "status": status,
        "detail": detail,
    }


def build_company_dashboard_cards(company_os: dict, gate: dict) -> list[dict]:
    """Operator-facing company OS posture cards for the web dashboard."""
    workflows = company_os.get("workflows", {})
    governance = company_os.get("human_governance", {})
    autonomy = company_os.get("autonomy", {})
    policy = company_os.get("policy", {})
    broker = company_os.get("broker", {})
    outcomes = company_os.get("outcomes", {})
    company_errors = list(company_os.get("errors") or [])
    workflow_errors = list(workflows.get("errors") or [])
    governance_errors = list(governance.get("errors") or [])
    policy_errors = list(policy.get("errors") or [])
    broker_errors = list(broker.get("errors") or [])
    outcome_errors = list(outcomes.get("errors") or [])

    hgl = int(governance.get("open_hgl_estimate") or 0)
    missing_skills = list(governance.get("missing_skills") or [])
    bottlenecks = list(governance.get("bottlenecks") or [])
    capacity_warnings = list(governance.get("capacity_warnings") or [])
    r3 = int(governance.get("r3_decisions_open") or 0)
    r4 = int(governance.get("r4_decisions_open") or 0)
    r5 = int(governance.get("r5_decisions_open") or 0)
    yellow = int(autonomy.get("yellow_workflows") or 0)
    red = int(autonomy.get("red_workflows") or 0)
    green = int(autonomy.get("green_workflows") or 0)
    candidate_count = int(policy.get("candidates") or 0)
    active_policies = int(policy.get("active_policies") or 0)
    proposed_policies = int(policy.get("proposed_policies") or 0)
    real_side_effects = bool(broker.get("real_side_effects_enabled"))
    mock_observations = int(broker.get("mock_observations") or 0)
    broker_tickets = list(broker.get("tickets_with_broker_evidence") or [])
    open_outcomes = int(outcomes.get("open") or 0)
    recorded_outcomes = int(outcomes.get("recorded") or 0)
    invalidated_outcomes = int(outcomes.get("invalidated") or 0)
    workflow_count = int(workflows.get("active") or 0)

    first_error = (
        workflow_errors
        or governance_errors
        or policy_errors
        or broker_errors
        or outcome_errors
        or company_errors
    )
    governance_state_error = workflow_errors or governance_errors or company_errors
    hgl_status = "bad" if missing_skills or capacity_warnings or governance_errors else ("watch" if hgl else "ok")
    decision_status = "bad" if governance_state_error or r5 else ("watch" if r3 or r4 else "ok")
    missing_status = "bad" if governance_state_error or missing_skills else "ok"
    bottleneck_status = "bad" if governance_state_error else ("watch" if bottlenecks else "ok")
    autonomy_status = "bad" if red or workflow_errors else ("watch" if yellow else "ok")
    policy_status = "bad" if policy_errors else ("watch" if candidate_count else "ok")
    broker_status = "bad" if real_side_effects or broker_errors else "ok"
    outcome_status = "bad" if outcome_errors or invalidated_outcomes else ("watch" if open_outcomes else "ok")
    if gate.get("enabled"):
        secure_status = "ok" if gate.get("available") and gate.get("initialized") else "bad"
        secure_value = "signed gate"
        secure_detail = "ForgeGate is enabled; verify tickets against the signed gate section."
    else:
        secure_status = "watch"
        secure_value = "honor-system"
        secure_detail = "Signed acceptance is disabled; run doctor secure before relying on autonomous acceptance."

    return [
        company_card(
            "human_governance_load",
            "Human Governance Load",
            f"{hgl} HGL",
            hgl_status,
            governance_errors[0]
            if governance_errors
            else "Open estimate across active workflows; capacity and missing skills escalate this card.",
        ),
        company_card(
            "high_risk_decisions",
            "R3/R4/R5 Decisions",
            "unknown" if governance_state_error else f"{r3}/{r4}/{r5}",
            decision_status,
            governance_state_error[0]
            if governance_state_error
            else "Open high-risk decisions stay visible; R5 requires explicit human authority.",
        ),
        company_card(
            "missing_skills",
            "Missing Skills",
            "unknown" if governance_state_error else str(len(missing_skills)),
            missing_status,
            governance_state_error[0]
            if governance_state_error
            else ", ".join(missing_skills[:3]) if missing_skills else "All active workflow skills are covered.",
        ),
        company_card(
            "bottlenecks",
            "Bottlenecks",
            "unknown" if governance_state_error else str(len(bottlenecks)),
            bottleneck_status,
            governance_state_error[0]
            if governance_state_error
            else ", ".join(bottlenecks[:3]) if bottlenecks else "No active human or role bottlenecks detected.",
        ),
        company_card(
            "autonomy_gates",
            "Autonomy Gates",
            f"{green}/{yellow}/{red}",
            autonomy_status,
            workflow_errors[0] if workflow_errors else "Green/yellow/red workflow gates; red and yellow states are never hidden.",
        ),
        company_card(
            "policy_candidates",
            "Policy Candidates",
            "unknown" if policy_errors else str(candidate_count),
            policy_status,
            policy_errors[0]
            if policy_errors
            else f"Simulation-only suggestions; {active_policies} active and {proposed_policies} proposed policy files.",
        ),
        company_card(
            "broker_posture",
            "Broker Posture",
            "unknown" if broker_errors else ("real side effects" if real_side_effects else "mock / observed-only"),
            broker_status,
            (
                broker_errors[0]
                if broker_errors
                else
                "Real side effects are reported; confirm a sandbox boundary before trusting broker authority."
                if real_side_effects
                else f"Mock/observed-only broker evidence across {len(broker_tickets)} ticket(s) and {mock_observations} observation(s)."
            ),
        ),
        company_card(
            "outcomes",
            "Outcomes",
            "unknown" if outcome_errors else f"{open_outcomes}/{recorded_outcomes}/{invalidated_outcomes}",
            outcome_status,
            outcome_errors[0]
            if outcome_errors
            else "Open/recorded/invalidated outcomes; invalidated outcomes require review before policy learning.",
        ),
        company_card(
            "secure_posture",
            "Secure Posture",
            secure_value,
            secure_status,
            secure_detail,
        ),
        company_card(
            "active_workflows",
            "Active Workflows",
            "unknown" if first_error else str(workflow_count),
            "bad" if first_error else ("ok" if workflow_count else "watch"),
            first_error[0]
            if first_error
            else "Adopted workflows are the source for HGL, gates, and company OS governance cards.",
        ),
    ]


# ---------------------------------------------------------------- snapshot

def snapshot_dict(root: Path, *, full: bool = False) -> dict:
    root = Path(root).resolve()
    config = parse_config(root)
    default_branch = cfg(config, "default_branch", "main")
    reports_dir = cfg(config, "reports_dir", "reports")
    evidence_dir = cfg(config, "evidence_dir", "reports/evidence")

    reports_index = build_reports_index(root, reports_dir)
    evidence_index = build_evidence_index(root, evidence_dir)

    tickets = []
    counts = {s: 0 for s in ["open", "claimed", "blocked", "needs-human", "in-review", "reopened", "accepted"]}
    open_dir = root / cfg(config, "tickets_open_dir", "tickets/open")
    closed_dir = root / cfg(config, "tickets_closed_dir", "tickets/closed")
    sources = [(p, "active") for p in md_files(open_dir)]
    if full:
        sources += [(p, "accepted") for p in md_files(closed_dir)]
    else:
        counts["accepted"] = len(md_files(closed_dir))

    for path, state in sources:
        fm = parse_frontmatter(path)
        ticket_id = scalar(fm, "id") or path.stem
        status = scalar(fm, "status") or ("accepted" if state == "accepted" else "open")
        if status in counts:
            counts[status] += 1
        evidence = evidence_index.get(
            ticket_id,
            {
                "path": f"{evidence_dir}/{ticket_id}",
                "files": [],
                "has_log": False,
                "has_junit": False,
                "has_sarif": False,
                "has_manifest": False,
                "file_count": 0,
                "executor_evidence": [],
            },
        )
        base_reports = reports_index.get(
            ticket_id, {"technical": False, "reviewer": False, "human": False, "custom": []}
        )
        custom = []
        for name in listval(fm, "required_reports"):
            if name in ("specialist", "technical", "reviewer", "human", "founder"):
                continue
            present = any(
                kind.startswith(name) for kind in base_reports.get("custom", [])
            )
            custom.append({"name": name, "present": present})
        reports = {
            "technical": base_reports["technical"],
            "reviewer": base_reports["reviewer"],
            "human": base_reports["human"],
            "custom": custom,
        }
        action = next_action(fm, ticket_id, status, default_branch, evidence, reports, config)
        tickets.append(
            {
                "id": ticket_id,
                "title": scalar(fm, "title"),
                "status": status,
                "risk": scalar(fm, "risk"),
                "priority": scalar(fm, "priority"),
                "stream": scalar(fm, "stream"),
                "state": state,
                "path": str(path.relative_to(root)),
                "allowed_paths": listval(fm, "allowed_paths"),
                "forbidden_paths": listval(fm, "forbidden_paths"),
                "verification": listval(fm, "verification"),
                "required_reports": listval(fm, "required_reports"),
                "claimed_by": scalar(fm, "claimed_by"),
                "claimed_at": scalar(fm, "claimed_at"),
                "created_by_role": scalar(fm, "created_by_role") or scalar(fm, "issued_by_role"),
                "delegated_to_role": scalar(fm, "delegated_to_role") or scalar(fm, "delegate_to_role"),
                "accepted_by": scalar(fm, "accepted_by"),
                "accepted_at": scalar(fm, "accepted_at"),
                "implemented_by": scalar(fm, "implemented_by"),
                "claim_ref": scalar(fm, "claim_ref"),
                "claim_expires_at": scalar(fm, "claim_expires_at"),
                "claim_heartbeat_at": scalar(fm, "claim_heartbeat_at"),
                "requires_review": scalar(fm, "requires_review") == "true",
                "requires_human_confirmation": scalar(fm, "requires_human_confirmation") == "true",
                "serves_goal": scalar(fm, "serves_goal"),
                "model_hint": scalar(fm, "model_hint"),
                "branch": scalar(fm, "branch") or f"ticket/{ticket_id}",
                "worktree": scalar(fm, "worktree"),
                "evidence": evidence,
                "reports": reports,
                "next_action": action,
                "lease": lease_info(fm),
            }
        )

    proposals = []
    for path in md_files(root / cfg(config, "tickets_proposed_dir", "tickets/proposed")):
        fm = parse_frontmatter(path)
        proposals.append(
            {
                "id": scalar(fm, "id") or path.stem,
                "title": scalar(fm, "title"),
                "status": scalar(fm, "status"),
                "planner": scalar(fm, "planner"),
                "model": scalar(fm, "model"),
                "path": str(path.relative_to(root)),
                "adopted_ticket": scalar(fm, "adopted_ticket"),
                "adopted_at": scalar(fm, "adopted_at"),
            }
        )

    # Operator inbox: active, non-clear tickets ordered by category priority.
    inbox = []
    for ticket in tickets:
        if ticket["state"] != "active":
            continue
        action = ticket["next_action"]
        category = inbox_category(
            ticket["status"], action["actor"], action["severity"], action["label"]
        )
        inbox.append(
            {
                "ticket_id": ticket["id"],
                "title": ticket["title"],
                "status": ticket["status"],
                "category": category,
                "category_label": INBOX_LABELS[category],
                "label": action["label"],
                "detail": action["detail"],
                "command": action["command"],
                "actor": action["actor"],
                "severity": action["severity"],
            }
        )
    inbox_counts = {key.replace("-", "_"): 0 for key in INBOX_PRIORITY}
    for item in inbox:
        inbox_counts[item["category"].replace("-", "_")] += 1

    decisions = []
    for path in md_files(root / cfg(config, "decisions_open_dir", "decisions/open")):
        fm = parse_frontmatter(path)
        decision_id = scalar(fm, "id") or path.stem
        decisions.append(
            {
                "id": decision_id,
                "title": scalar(fm, "title"),
                "respond_by": scalar(fm, "respond_by"),
                "ticket": scalar(fm, "ticket"),
                "goal": scalar(fm, "goal"),
                "recommended_option": scalar(fm, "recommended_option"),
                "command": f"./bin/palari decide record {decision_id} --choice N --by NAME",
            }
        )

    if inbox:
        ranked = sorted(
            inbox, key=lambda item: INBOX_PRIORITY.index(item["category"])
        )
        top = ranked[0]
        operator_next = {
            "label": top["label"],
            "detail": top["detail"],
            "command": top["command"],
            "actor": top["actor"],
            "severity": top["severity"],
        }
        operator = {
            "has_active_work": True,
            "next_action": operator_next,
            "inbox": inbox,
            "inbox_counts": inbox_counts,
            "open_decisions": decisions,
        }
    else:
        operator = {
            "has_active_work": False,
            "next_action": {
                "label": "Create or adopt a ticket",
                "detail": "No active tickets are waiting; define the next scoped slice when there is work to delegate.",
                "command": "./bin/palari ticket create TICKET-ID TITLE --allowed PATH --verify COMMAND",
                "actor": "human",
                "severity": "clear",
            },
            "inbox": [],
            "inbox_counts": inbox_counts,
            "open_decisions": decisions,
        }

    # Roles: shallow frontmatter only.
    role_items = []
    role_counts = {}
    for state, key in (("active", "roles_active_dir"), ("proposed", "roles_proposed_dir"), ("revoked", "roles_revoked_dir")):
        directory = root / cfg(config, key, f"roles/{state}")
        files = md_files(directory)
        role_counts[state] = len(files)
        for path in files:
            fm = parse_frontmatter(path)
            role_items.append(
                {
                    "id": scalar(fm, "id") or path.stem,
                    "title": scalar(fm, "title"),
                    "status": scalar(fm, "status") or state,
                    "tier": scalar(fm, "tier"),
                    "max_risk": scalar(fm, "max_risk"),
                    "path": str(path.relative_to(root)),
                    "allowed_paths": listval(fm, "allowed_paths"),
                }
            )
    roles = {
        "counts": role_counts,
        "lint": {
            "ok": True,
            "issues": 0,
            "checked": len(role_items),
            "mode": "shallow",
            "command": "./bin/palari role lint",
            "detail": "Skipped in the fast snapshot; run ./bin/palari role lint or ./bin/palari snapshot --json --full for full diagnostics.",
        },
        "items": role_items,
    }

    # Memory: shallow, no indexing subprocess.
    memory_dir = cfg(config, "memory_dir", "memory")
    memory_files = []
    mdir = root / memory_dir
    if mdir.is_dir():
        memory_files = [p for p in mdir.rglob("*.md") if p.name != "README.md"]
    memory_active = memory_proposed = 0
    for path in memory_files:
        status = scalar(parse_frontmatter(path), "status")
        if status == "active":
            memory_active += 1
        elif status == "proposed":
            memory_proposed += 1
    memory = {
        "enabled": cfg(config, "memory_enabled", "true") != "false",
        "dir": memory_dir,
        "backend": cfg(config, "memory_backend", "sqlite"),
        "total": len(memory_files),
        "active": memory_active,
        "proposed": memory_proposed,
        "stale_review": 0,
        "lint_ok": True,
        "index_exists": (mdir / "index.sqlite").exists() or (mdir / "index.json").exists(),
    }

    if company_os_snapshot is not None:
        company_os = company_os_snapshot.build_company_os(root, config)
    else:
        company_os = {
            "errors": ["company OS snapshot helper unavailable"],
            "workflows": {
                "active": 0,
                "proposed": 0,
                "closed": 0,
                "items": [],
                "errors": ["company OS snapshot helper unavailable"],
            },
            "humans": {"active": 0, "proposed": 0, "revoked": 0, "coverage_gaps": []},
            "human_governance": {
                "open_hgl_estimate": 0,
                "r3_decisions_open": 0,
                "r4_decisions_open": 0,
                "r5_decisions_open": 0,
                "missing_skills": [],
                "bottlenecks": [],
                "capacity_warnings": ["company OS snapshot helper unavailable"],
                "errors": ["company OS snapshot helper unavailable"],
            },
            "autonomy": {"green_workflows": 0, "yellow_workflows": 0, "red_workflows": 0},
            "policy": {
                "simulation_only": True,
                "candidates": 0,
                "active_policies": 0,
                "proposed_policies": 0,
                "errors": ["company OS snapshot helper unavailable"],
            },
            "broker": {
                "real_side_effects_enabled": False,
                "mock_observations": 0,
                "tickets_with_broker_evidence": [],
                "errors": ["company OS snapshot helper unavailable"],
            },
            "outcomes": {
                "open": 0,
                "recorded": 0,
                "invalidated": 0,
                "errors": ["company OS snapshot helper unavailable"],
            },
        }

    # Gate: the fast path never imports the crypto kernel in-process. When
    # the gate is disabled, emit the cheap static section. When enabled, run
    # the kernel CLI once (~0.6s, dominated by the cryptography import) so
    # gate-enabled repos keep accurate fingerprints and per-ticket verdicts
    # without falling back to the multi-second legacy path. If the kernel is
    # unavailable, degrade to a shallow section that says how to verify.
    gate_enabled = cfg_nested(config, "gate", "enabled", "false") == "true"
    gate_layout = cfg_nested(config, "gate", "layout", "layouts/palari-change.yml")
    gate = {
        "available": False,
        "enabled": gate_enabled,
        "initialized": (root / ".palari" / "gate").is_dir(),
        "layout": gate_layout,
        "max_age_seconds": int(cfg_nested(config, "gate", "max_age_seconds", "86400") or 86400),
        "root_fingerprint": "",
        "tickets": {},
    }
    if gate_enabled:
        adapter = root / "adapters" / "gate" / "palari_gate.py"
        try:
            result = subprocess.run(
                [sys.executable, "-B", str(adapter), "--root", str(root), "status"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if result.returncode == 0:
                gate = json.loads(result.stdout)
            else:
                gate["mode"] = "shallow"
                gate["detail"] = (
                    "Fast snapshot could not run the gate kernel; run "
                    "./bin/palari gate status or ./bin/palari snapshot --json --full."
                )
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
            gate["mode"] = "shallow"
            gate["detail"] = (
                "Fast snapshot could not run the gate kernel; run "
                "./bin/palari gate status or ./bin/palari snapshot --json --full."
            )

    company_os["dashboard_cards"] = build_company_dashboard_cards(company_os, gate)

    # Git + hygiene-classified dirtiness: the one subprocess.
    git_info = {"branch": "unknown", "status": "", "mode": "skipped-fast"}
    dirty_total = dirty_generated = dirty_source = 0
    if os.environ.get("PALARI_FAST_GIT", "1") != "0":
        try:
            result = subprocess.run(
                ["git", "-C", str(root), "status", "--porcelain=v1", "--branch"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0:
                lines = result.stdout.rstrip("\n").split("\n") if result.stdout.strip() else []
                branch = "unknown"
                if lines and lines[0].startswith("## "):
                    branch = lines[0][3:].split("...")[0]
                git_info = {"branch": branch, "status": result.stdout.rstrip("\n")}
                patterns = config["lists"].get("hygiene_generated_paths") or HYGIENE_DEFAULT_GENERATED
                compiled = [glob_to_regex(p) for p in patterns]
                for line in lines[1:]:
                    if not line.strip():
                        continue
                    path = line[3:]
                    if " -> " in path:
                        path = path.split(" -> ")[-1]
                    path = strip_quotes(path).rstrip("/")
                    dirty_total += 1
                    if any(rx.match(path) or rx.match(path + "/x") for rx in compiled):
                        dirty_generated += 1
                    else:
                        dirty_source += 1
        except (OSError, subprocess.TimeoutExpired):
            pass

    stale_claims = sum(
        1 for t in tickets if t["status"] == "claimed" and t["lease"]["status"] == "expired"
    )
    missing_evidence = sum(
        1
        for t in tickets
        if t["state"] == "active"
        and t["status"] in ("in-review",)
        and not t["evidence"]["has_manifest"]
    )

    accepted = counts["accepted"]
    active_total = sum(counts[s] for s in ACTIVE_STATUSES)
    status_text = "\n".join(
        [
            "Palari Orchestration status",
            f"root: {root}",
            f"project: {cfg(config, 'project_name', 'Palari Orchestrator')}",
            f"proposals: {len(proposals)} proposed",
            f"tickets: {active_total} active, {accepted} accepted",
            f"open:{counts['open']} claimed:{counts['claimed']} blocked:{counts['blocked']} "
            f"needs-human:{counts['needs-human']} in-review:{counts['in-review']} reopened:{counts['reopened']}",
            f"reports: {sum(1 for f in (root / reports_dir).glob('*.md') if f.name != 'README.md') + sum(1 for f in (root / reports_dir).glob('*.markdown'))} specialist/reviewer, "
            f"{sum(1 for f in (root / cfg(config, 'human_reports_dir', 'reports/human')).glob('*.md') if f.name != 'README.md') if (root / cfg(config, 'human_reports_dir', 'reports/human')).is_dir() else 0} human",
            f"evidence: {sum(1 for f in (root / evidence_dir).rglob('*') if f.is_file() and f.name != '.gitkeep') if (root / evidence_dir).is_dir() else 0} files",
            f"git: {dirty_total} changed paths in workspace ({dirty_generated} generated, {dirty_source} source)",
        ]
    )

    authority_profile = cfg(config, "authority_profile", "team-safe")
    authority_defaults = {
        "solo-founder": ("true", "true", "true", "true", "true"),
        "team-safe": ("true", "true", "true", "false", "false"),
        "strict": ("false", "false", "false", "false", "false"),
    }.get(authority_profile, ("true", "true", "true", "false", "false"))
    authority = {
        "profile": authority_profile,
        "agent_can_commit": cfg(config, "agent_can_commit", authority_defaults[0]),
        "agent_can_push_branch": cfg(config, "agent_can_push_branch", authority_defaults[1]),
        "agent_can_open_pr": cfg(config, "agent_can_open_pr", authority_defaults[2]),
        "agent_can_merge_main": cfg(config, "agent_can_merge_main", authority_defaults[3]),
        "agent_can_accept": cfg(config, "agent_can_accept", authority_defaults[4]),
    }

    workflow_path = ".github/workflows/palari.yml"
    ruleset_path = ".github/palari-required-checks.ruleset.json"
    workflow_text = read_text(root / workflow_path)
    workflow = {
        "workflow_installed": (root / workflow_path).is_file(),
        "ruleset_template": (root / ruleset_path).is_file(),
        "merge_group": "merge_group" in workflow_text,
        "attestation": "attestation" in workflow_text or "attest" in workflow_text,
        "sarif": "sarif" in workflow_text.lower(),
        "workflow_path": workflow_path,
        "ruleset_path": ruleset_path,
    }

    return {
        "project": cfg(config, "project_name", "Palari Orchestrator"),
        "snapshot_mode": "full" if full else "fast",
        "snapshot_engine": "python-fast",
        "root": str(root),
        "generated_at": now_utc(),
        "config": {
            "default_branch": default_branch,
            "scope_overlap_policy": cfg(config, "scope_overlap_policy", "block"),
            "claim_lease_seconds": cfg(config, "claim_lease_seconds", "300"),
            "authority_profile": authority_profile,
            "evidence_dir": evidence_dir,
        },
        "counts": {"proposals": len(proposals), **{k: counts[k] for k in ["open", "claimed", "blocked", "needs-human", "in-review", "reopened", "accepted"]}},
        "proposals": proposals,
        "tickets": tickets,
        "operator": operator,
        "roles": roles,
        "overlaps": [],
        "workflow": workflow,
        "memory": memory,
        "company_os": company_os,
        "gate": gate,
        "health": {
            "status_ok": True,
            "dirty_paths": dirty_total,
            "generated_dirty_paths": dirty_generated,
            "source_dirty_paths": dirty_source,
            "stale_claims": stale_claims,
            "missing_evidence": missing_evidence,
            "overlaps": 0,
        },
        "git": git_info,
        "palari_status": {"ok": True, "code": 0, "stdout": status_text, "stderr": ""},
        "authority": authority,
        "commands": {
            "status": "./bin/palari status",
            "status_next": "./bin/palari status --next",
            "hygiene": "./bin/palari hygiene",
            "authority": "./bin/palari authority",
            "ticket_audit": "./bin/palari ticket audit",
            "lint": "./bin/palari lint",
            "scope_overlaps": "./bin/palari scope-overlaps",
            "ruleset": "./bin/palari github ruleset-command --repo OWNER/REPO",
        },
    }


def render_legacy_format(snapshot: dict) -> str:
    """Match the legacy Bash snapshot byte format: pretty top-level keys
    (two-space indent, `": "` separator) with compact nested values
    (`":"`/`","` separators), so every existing grep and parser keeps
    working unchanged."""
    lines = ["{"]
    keys = list(snapshot.keys())
    for i, key in enumerate(keys):
        # The gate section historically came from the kernel CLI, which emits
        # spaced separators; everything else is Bash-compact. Stay
        # bug-compatible so existing greps keep working.
        separators = (", ", ": ") if key == "gate" else (",", ":")
        value = json.dumps(snapshot[key], separators=separators)
        comma = "," if i < len(keys) - 1 else ""
        lines.append(f'  "{key}": {value}{comma}')
    lines.append("}")
    return "\n".join(lines)


def status_text_from_snapshot(snapshot: dict, show_next: bool) -> str:
    lines = [snapshot["palari_status"]["stdout"]]
    if show_next:
        action = snapshot["operator"]["next_action"]
        lines.append("")
        lines.append("Next required action")
        inbox = snapshot["operator"]["inbox"]
        if inbox:
            top = inbox[0]
            lines.append(f"{top['ticket_id']} [{top['status']}]")
        lines.append(f"  {action['label']}")
        lines.append(f"  {action['detail']}")
        if action["command"]:
            lines.append(f"  run: {action['command']}")
    return "\n".join(lines)


def main() -> int:
    args = sys.argv[1:]
    root = Path.cwd()
    pretty = False
    status_mode = False
    show_next = False
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--root":
            root = Path(args[i + 1])
            i += 2
            continue
        if arg == "--pretty":
            pretty = True
        elif arg == "--status":
            status_mode = True
        elif arg == "--next":
            show_next = True
        elif arg in ("--json", "--fast"):
            pass
        else:
            print(f"fast_snapshot: unknown option {arg}", file=sys.stderr)
            return 2
        i += 1

    snapshot = snapshot_dict(root, full=False)
    if status_mode:
        print(status_text_from_snapshot(snapshot, show_next))
        return 0
    print(render_legacy_format(snapshot) if not pretty else json.dumps(snapshot, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        # Downstream consumer (head, grep -q) closed the pipe; not an error.
        os._exit(0)
