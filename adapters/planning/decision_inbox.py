#!/usr/bin/env python3
"""Read-only decision inbox for workflow and open decision artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import hgl
import policy_candidates
from artifacts import find_frontmatter_file, frontmatter_dict, md_files, risk_number


RISKS = ["R0", "R1", "R2", "R3", "R4", "R5"]
OPEN_DECISION_HGL = {"R0": 0, "R1": 1, "R2": 3, "R3": 5, "R4": 8, "R5": 20}


def coverage_status(coverage_rows: list[dict[str, Any]]) -> str:
    if not coverage_rows:
        return "missing_skill"
    covered_counts = [len(row.get("covered_by", [])) for row in coverage_rows]
    if all(count > 0 for count in covered_counts):
        if any(count == 1 for count in covered_counts):
            return "covered_by_one"
        return "covered_by_two_or_more"
    if any(row.get("at_capacity", []) for row in coverage_rows):
        return "at_capacity"
    if any(row.get("under_authorized", []) for row in coverage_rows):
        return "missing_authorized_human"
    if any(row.get("underleveled", []) for row in coverage_rows):
        return "underleveled"
    return "missing_skill"


def required_skills(coverage_rows: list[dict[str, Any]]) -> dict[str, str]:
    return {
        str(row["skill"]): str(row["level"])
        for row in coverage_rows
        if row.get("skill") and row.get("level")
    }


def eligible_humans(coverage_rows: list[dict[str, Any]]) -> list[str]:
    return sorted(
        {
            str(human)
            for row in coverage_rows
            for human in row.get("covered_by", [])
        }
    )


def workflow_items(root: Path, args: argparse.Namespace) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    workflow_dirs = [
        ("active", args.workflows_active_dir),
        ("proposed", args.workflows_proposed_dir),
    ]
    for lifecycle, rel_dir in workflow_dirs:
        for path in md_files(root, rel_dir):
            try:
                artifact = hgl.parse_frontmatter(path)
                workflow_id = artifact.fields.get("id", path.stem)
                hgl_args = SimpleNamespace(
                    workflow=workflow_id,
                    workflows_proposed_dir=args.workflows_proposed_dir,
                    workflows_active_dir=args.workflows_active_dir,
                    workflows_closed_dir=args.workflows_closed_dir,
                    humans_active_dir=args.humans_active_dir,
                )
                data = hgl.analyze(root, hgl_args)
            except (OSError, ValueError, SystemExit):
                continue
            for decision in data.get("decisions", []):
                coverage_rows = list(decision.get("coverage", []))
                skills = required_skills(coverage_rows)
                items.append(
                    {
                        "source": "workflow_expected_decision",
                        "id": f"{workflow_id}:{decision.get('kind', '')}:{decision.get('title', '')}",
                        "title": str(decision.get("title", "")),
                        "risk": str(decision.get("risk", "R0")),
                        "hgl_score": int(decision.get("score", 0)),
                        "kind": str(decision.get("kind", "")),
                        "workflow": workflow_id,
                        "workflow_title": str(data.get("title", "")),
                        "workflow_status": lifecycle,
                        "ticket": "",
                        "decision": "",
                        "required_skills": skills,
                        "eligible_humans": eligible_humans(coverage_rows),
                        "coverage_status": coverage_status(coverage_rows),
                        "path": str(path.relative_to(root)),
                    }
                )
    return items


def ticket_risk(root: Path, args: argparse.Namespace, ticket_id: str) -> tuple[str, str]:
    if not ticket_id:
        return "R0", ""
    found = find_frontmatter_file(
        root,
        [args.tickets_open_dir, args.tickets_closed_dir],
        ticket_id,
        required=False,
    )
    if not found:
        return "R0", ""
    ticket_path, ticket = found
    return str(ticket.get("risk", "R0") or "R0"), str(ticket_path.relative_to(root))


def open_decision_items(root: Path, args: argparse.Namespace) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for path in md_files(root, args.decisions_open_dir):
        decision = frontmatter_dict(path)
        ticket_id = str(decision.get("ticket", "") or "")
        risk, ticket_path = ticket_risk(root, args, ticket_id)
        items.append(
            {
                "source": "open_decision",
                "id": str(decision.get("id", path.stem)),
                "title": str(decision.get("title", "")),
                "risk": risk,
                "hgl_score": OPEN_DECISION_HGL.get(risk, 0),
                "kind": "record",
                "workflow": "",
                "workflow_title": "",
                "workflow_status": "",
                "ticket": ticket_id,
                "ticket_path": ticket_path,
                "decision": str(decision.get("id", path.stem)),
                "required_skills": {},
                "eligible_humans": [],
                "coverage_status": "human_record_required",
                "recommended_option": str(decision.get("recommended_option", "")),
                "respond_by": str(decision.get("respond_by", "")),
                "path": str(path.relative_to(root)),
            }
        )
    return items


def policy_candidate_count(root: Path, args: argparse.Namespace) -> int:
    candidate_args = SimpleNamespace(
        tickets_open_dir=args.tickets_open_dir,
        tickets_closed_dir=args.tickets_closed_dir,
        decisions_decided_dir=args.decisions_decided_dir,
        outcomes_recorded_dir=args.outcomes_recorded_dir,
    )
    try:
        data = policy_candidates.build_candidates(root, candidate_args)
    except (OSError, ValueError):
        return 0
    return int(data.get("candidate_count", 0))


def sorted_items(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(
        items,
        key=lambda item: (
            -risk_number(str(item.get("risk", "R0"))),
            -int(item.get("hgl_score", 0)),
            str(item.get("source", "")),
            str(item.get("title", "")),
        ),
    )


def build_inbox(root: Path, args: argparse.Namespace) -> dict[str, Any]:
    items = sorted_items(workflow_items(root, args) + open_decision_items(root, args))
    counts = {risk: 0 for risk in RISKS}
    for item in items:
        risk = str(item.get("risk", "R0"))
        if risk in counts:
            counts[risk] += 1
    return {
        "read_only": True,
        "created_or_recorded_decisions": False,
        "total_hgl": sum(int(item.get("hgl_score", 0)) for item in items),
        "decision_count": len(items),
        "counts_by_risk": counts,
        "policy_candidate_count": policy_candidate_count(root, args),
        "items": items,
        "recommended_order": [
            {
                "rank": index + 1,
                "risk": item["risk"],
                "title": item["title"],
                "source": item["source"],
                "hgl_score": item["hgl_score"],
            }
            for index, item in enumerate(items[:10])
        ],
    }


def skill_text(skills: dict[str, str]) -> str:
    if not skills:
        return "(none)"
    return ", ".join(f"{skill} {level}" for skill, level in sorted(skills.items()))


def print_text(data: dict[str, Any]) -> str:
    lines = [
        "Decision Inbox",
        f"Total HGL: {data['total_hgl']}",
    ]
    for risk in reversed(RISKS):
        count = data["counts_by_risk"].get(risk, 0)
        if count:
            noun = "decision" if count == 1 else "decisions"
            lines.append(f"{risk}: {count} {noun}")
            for item in [row for row in data["items"] if row["risk"] == risk]:
                location = item["workflow"] or item["decision"]
                eligible = ", ".join(item["eligible_humans"] or ["(none)"])
                lines.append(f"- {item['title']} [{item['source']}]")
                lines.append(f"  location: {location}")
                lines.append(f"  skills: {skill_text(item['required_skills'])}")
                lines.append(f"  coverage: {item['coverage_status']}")
                lines.append(f"  eligible: {eligible}")
                lines.append(f"  HGL: {item['hgl_score']}")
    lines.append(f"Policy candidates: {data['policy_candidate_count']} low-risk repeated decisions")
    lines.append("Recommended order:")
    if data["recommended_order"]:
        for item in data["recommended_order"]:
            lines.append(f"{item['rank']}. {item['risk']} {item['title']}")
    else:
        lines.append("1. (none)")
    lines.append("Read-only: no decisions were created or recorded.")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--workflows-proposed-dir", required=True)
    parser.add_argument("--workflows-active-dir", required=True)
    parser.add_argument("--workflows-closed-dir", required=True)
    parser.add_argument("--humans-active-dir", required=True)
    parser.add_argument("--decisions-open-dir", required=True)
    parser.add_argument("--decisions-decided-dir", required=True)
    parser.add_argument("--tickets-open-dir", required=True)
    parser.add_argument("--tickets-closed-dir", required=True)
    parser.add_argument("--outcomes-recorded-dir", required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    data = build_inbox(Path(args.root), args)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(print_text(data), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
