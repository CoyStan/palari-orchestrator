#!/usr/bin/env python3
"""Read-only simulation for Palari policy acceptance."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


RISK_ORDER = {f"R{i}": i for i in range(6)}
DEFAULT_POLICY_RISK_MAX = "R2"


def parse_frontmatter(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return {}
    data: dict[str, Any] = {}
    key: str | None = None
    for line in lines[1:]:
        if line == "---":
            break
        if re.match(r"^[A-Za-z0-9_]+:", line):
            raw_key, raw_value = line.split(":", 1)
            key = raw_key
            value = raw_value.strip().strip("\"'")
            data[key] = value
            continue
        if key and re.match(r"^\s*-\s+", line):
            value = re.sub(r"^\s*-\s+", "", line).strip().strip("\"'")
            if not isinstance(data.get(key), list):
                data[key] = []
            data[key].append(value)
    return data


def md_files(root: Path, rel_dir: str) -> list[Path]:
    directory = root / rel_dir
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.glob("*.md") if path.name != "README.md")


def find_frontmatter_file(root: Path, dirs: list[str], artifact_id: str) -> tuple[Path, dict[str, Any]]:
    for rel_dir in dirs:
        for path in md_files(root, rel_dir):
            data = parse_frontmatter(path)
            if data.get("id") == artifact_id:
                return path, data
    raise SystemExit(f"error: artifact not found: {artifact_id}")


def named_report_exists(root: Path, reports_dir: str, ticket_id: str, suffix: str) -> bool:
    path = root / reports_dir / f"{ticket_id}-{suffix}.md"
    return path.is_file() and path.stat().st_size > 0


def manifest_integrity_ok(evidence_dir: Path) -> bool:
    manifest_path = evidence_dir / "manifest.json"
    if not manifest_path.is_file():
        return False
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return False
    if manifest.get("status") != "passed":
        return False
    for artifact in manifest.get("artifacts", []):
        name = artifact.get("name")
        expected = artifact.get("sha256")
        if not name or not expected:
            return False
        path = evidence_dir / name
        if not path.is_file():
            return False
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            return False
    return True


def junit_ok(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size == 0:
        return False
    text = path.read_text(encoding="utf-8", errors="ignore")
    return "<testcase" in text and not re.search(r'(failures|errors)="[1-9][0-9]*"', text)


def evidence_score(root: Path, args: argparse.Namespace, ticket_id: str, ticket: dict[str, Any]) -> tuple[int, list[str]]:
    score = 0
    missing: list[str] = []
    evidence_dir = root / args.evidence_dir / ticket_id

    for name in ("verification.log", "palari.sarif", "manifest.json"):
        path = evidence_dir / name
        if path.is_file() and path.stat().st_size > 0:
            score += 5
        else:
            missing.append(f"{args.evidence_dir}/{ticket_id}/{name}")
    if junit_ok(evidence_dir / "junit.xml"):
        score += 5
    else:
        missing.append(f"{args.evidence_dir}/{ticket_id}/junit.xml")

    if manifest_integrity_ok(evidence_dir):
        score += 20
    else:
        missing.append("manifest integrity")

    if named_report_exists(root, args.reports_dir, ticket_id, "technical-report"):
        score += 15
    else:
        missing.append("technical report")

    risk = str(ticket.get("risk", ""))
    requires_review = str(ticket.get("requires_review", "")).lower() == "true"
    if requires_review or risk in {"R2", "R3", "R4", "R5"}:
        if named_report_exists(root, args.reports_dir, ticket_id, "reviewer-note"):
            score += 15
        else:
            missing.append("fresh reviewer note")
    else:
        score += 15

    requires_human = str(ticket.get("requires_human_confirmation", "")).lower() == "true"
    if requires_human or risk in {"R3", "R4", "R5"}:
        if named_report_exists(root, args.human_reports_dir, ticket_id, "human-report"):
            score += 10
        else:
            missing.append("human/founder report")
    else:
        score += 10

    verification_path = evidence_dir / "verification.log"
    verification = verification_path.read_text(encoding="utf-8", errors="ignore") if verification_path.is_file() else ""
    if "lint: ok" in verification:
        score += 10
    else:
        missing.append("lint pass marker")
    if "scope-check: ok" in verification:
        score += 10
    else:
        missing.append("scope-check pass marker")

    return score, missing


def risk_lte(left: str, right: str) -> bool:
    return RISK_ORDER.get(left, 99) <= RISK_ORDER.get(right, -1)


def policy_risk_allowed_by_default(risk: str) -> bool:
    return risk_lte(risk, DEFAULT_POLICY_RISK_MAX)


def no_open_decisions(root: Path, decisions_open_dir: str) -> bool:
    directory = root / decisions_open_dir
    if not directory.is_dir():
        return True
    return not any(
        path.suffix in {".md", ".markdown"} and path.name != ".gitkeep"
        for path in directory.iterdir()
    )


def evaluate_condition(condition: str, context: dict[str, Any]) -> tuple[bool, str]:
    if condition == "no_open_decisions":
        return (True, "no open decisions") if context["no_open_decisions"] else (False, "open decisions exist")
    if condition == "scope_check_passed":
        return (
            (True, "scope-check evidence passed")
            if context["scope_check_passed"]
            else (False, "scope-check pass marker missing")
        )
    match = re.match(r"^risk<=(R[0-2])$", condition)
    if match:
        limit = match.group(1)
        if risk_lte(context["ticket_risk"], limit):
            return True, f"ticket risk {context['ticket_risk']} <= {limit}"
        return False, f"ticket risk {context['ticket_risk']} exceeds {limit}"
    match = re.match(r"^evidence_score>=(\d+)$", condition)
    if match:
        threshold = int(match.group(1))
        if context["evidence_score"] >= threshold:
            return True, f"evidence score {context['evidence_score']} >= {threshold}"
        return False, f"evidence score {context['evidence_score']} below {threshold}"
    return False, f"unknown condition: {condition}"


def simulate_policy(policy_path: Path, policy: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    result = {
        "policy": str(policy.get("id", "missing")),
        "title": policy.get("title", ""),
        "file": str(policy_path),
        "status": policy.get("status", ""),
        "mode": policy.get("mode", ""),
        "risk_max": policy.get("risk_max", ""),
        "would_accept": False,
        "passed_conditions": [],
        "reasons": [],
    }
    reasons: list[str] = []
    passed: list[str] = []
    ticket_risk = context["ticket_risk"]

    if ticket_risk == "R5":
        reasons.append("R5 tickets are never eligible for policy acceptance")
    if policy.get("mode") != "simulation":
        reasons.append("policy mode is not simulation")
    risk_max = str(policy.get("risk_max", ""))
    if risk_max == "R5":
        reasons.append("policy risk_max R5 exceeds default simulation max R2; R5 is never policy-eligible")
    elif risk_max not in RISK_ORDER:
        reasons.append(f"policy risk_max is invalid: {risk_max or 'missing'}")
    elif not policy_risk_allowed_by_default(risk_max):
        reasons.append(
            f"policy risk_max {risk_max} exceeds default simulation max R2; "
            "R3/R4/R5 remain human decision classes"
        )
    elif not risk_lte(ticket_risk, risk_max):
        reasons.append(f"ticket risk {ticket_risk} exceeds policy risk_max {risk_max}")

    conditions = policy.get("conditions", [])
    if not isinstance(conditions, list) or not conditions:
        reasons.append("policy has no conditions")
        conditions = []
    for condition in conditions:
        ok, message = evaluate_condition(str(condition), context)
        if ok:
            passed.append(str(condition))
        else:
            reasons.append(message)

    result["passed_conditions"] = passed
    result["reasons"] = reasons
    result["would_accept"] = not reasons
    return result


def text_report(data: dict[str, Any]) -> str:
    lines = [
        f"Policy simulation for {data['ticket']}",
        f"Result: {data['result']}",
        "Mode: simulation only; no ticket state was changed.",
        f"Ticket risk: {data['ticket_risk']}",
        f"Evidence score: {data['evidence_score']}",
        "",
    ]
    if data["would_accept_by"]:
        lines.append("Would accept by:")
        lines.extend(f"- {item}" for item in data["would_accept_by"])
    else:
        lines.append("Would not accept:")
        lines.extend(f"- {reason}" for reason in data["would_not_accept_reasons"])
    lines.append("")
    lines.append("Policy checks:")
    for policy in data["policies"]:
        mark = "would_accept" if policy["would_accept"] else "would_not_accept"
        lines.append(f"- {policy['policy']}: {mark}")
        lines.extend(f"  - {reason}" for reason in policy["reasons"])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--ticket", required=True)
    parser.add_argument("--tickets-open-dir", required=True)
    parser.add_argument("--tickets-closed-dir", required=True)
    parser.add_argument("--policies-proposed-dir", required=True)
    parser.add_argument("--policies-active-dir", required=True)
    parser.add_argument("--policies-revoked-dir", required=True)
    parser.add_argument("--evidence-dir", required=True)
    parser.add_argument("--reports-dir", required=True)
    parser.add_argument("--human-reports-dir", required=True)
    parser.add_argument("--decisions-open-dir", required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    root = Path(args.root)
    ticket_path, ticket = find_frontmatter_file(root, [args.tickets_open_dir, args.tickets_closed_dir], args.ticket)
    ticket_id = str(ticket.get("id"))
    ticket_risk = str(ticket.get("risk", ""))
    score, missing = evidence_score(root, args, ticket_id, ticket)
    verification_path = root / args.evidence_dir / ticket_id / "verification.log"
    verification = verification_path.read_text(encoding="utf-8", errors="ignore") if verification_path.is_file() else ""
    context = {
        "ticket": ticket,
        "ticket_path": str(ticket_path.relative_to(root)),
        "ticket_risk": ticket_risk,
        "evidence_score": score,
        "evidence_missing": missing,
        "scope_check_passed": "scope-check: ok" in verification,
        "no_open_decisions": no_open_decisions(root, args.decisions_open_dir),
    }

    policy_paths = md_files(root, args.policies_proposed_dir) + md_files(root, args.policies_active_dir)
    policies = [simulate_policy(path.relative_to(root), parse_frontmatter(path), context) for path in policy_paths]
    would_accept_by = [policy["policy"] for policy in policies if policy["would_accept"]]
    reasons: list[str] = []
    if not policies:
        reasons.append("no proposed or active simulation policies found")
    for policy in policies:
        if policy["would_accept"]:
            continue
        for reason in policy["reasons"]:
            label = f"{policy['policy']}: {reason}"
            if label not in reasons:
                reasons.append(label)
    if missing and not would_accept_by:
        reasons.append("evidence missing: " + ", ".join(missing))

    data = {
        "ticket": ticket_id,
        "ticket_file": str(ticket_path.relative_to(root)),
        "ticket_risk": ticket_risk,
        "result": "would_accept" if would_accept_by else "would_not_accept",
        "simulation_only": True,
        "state_changed": False,
        "evidence_score": score,
        "evidence_missing": missing,
        "would_accept_by": would_accept_by,
        "would_not_accept_reasons": reasons,
        "policies": policies,
    }

    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(text_report(data), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
