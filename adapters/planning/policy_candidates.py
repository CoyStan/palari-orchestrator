#!/usr/bin/env python3
"""Suggest conservative policy candidates from decided decisions."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any


LOW_RISKS = {"R0", "R1", "R2"}
HGL_WEIGHTS = {"R0": 1, "R1": 1, "R2": 3}


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


def find_by_id(root: Path, dirs: list[str], artifact_id: str) -> tuple[Path, dict[str, Any]] | None:
    for rel_dir in dirs:
        for path in md_files(root, rel_dir):
            data = parse_frontmatter(path)
            if data.get("id") == artifact_id:
                return path, data
    return None


def option_text(decision: dict[str, Any], option: str) -> str:
    if not option.isdigit():
        return ""
    options = decision.get("options", [])
    index = int(option) - 1
    if isinstance(options, list) and 0 <= index < len(options):
        return str(options[index])
    return ""


def slug_token(value: str) -> str:
    token = re.sub(r"[^A-Za-z0-9]+", "-", value.upper()).strip("-")
    return token or "GENERAL"


def indexed_outcomes(root: Path, outcomes_recorded_dir: str) -> dict[str, list[dict[str, str]]]:
    index: dict[str, list[dict[str, str]]] = defaultdict(list)
    for path in md_files(root, outcomes_recorded_dir):
        outcome = parse_frontmatter(path)
        item = {
            "id": str(outcome.get("id", path.stem)),
            "title": str(outcome.get("title", "")),
            "status": str(outcome.get("status", "")),
            "file": str(path.relative_to(root)),
        }
        ticket = str(outcome.get("ticket", ""))
        decision = str(outcome.get("decision", ""))
        if ticket:
            index[ticket].append(item)
        if decision:
            index[decision].append(item)
    return index


def candidate_title(kind: str, risk: str) -> str:
    return f"{risk} {kind} repeated approvals"


def build_candidates(root: Path, args: argparse.Namespace) -> dict[str, Any]:
    outcomes = indexed_outcomes(root, args.outcomes_recorded_dir)
    groups: dict[tuple[str, str, str, str, str], list[dict[str, Any]]] = defaultdict(list)
    inspected = 0
    skipped_high_risk = 0
    skipped_no_ticket = 0
    skipped_not_recommended = 0

    for decision_path in md_files(root, args.decisions_decided_dir):
        decision = parse_frontmatter(decision_path)
        if decision.get("status") != "decided":
            continue
        inspected += 1
        ticket_id = str(decision.get("ticket", ""))
        if not ticket_id:
            skipped_no_ticket += 1
            continue
        found = find_by_id(root, [args.tickets_open_dir, args.tickets_closed_dir], ticket_id)
        if not found:
            skipped_no_ticket += 1
            continue
        ticket_path, ticket = found
        risk = str(ticket.get("risk", ""))
        if risk not in LOW_RISKS:
            skipped_high_risk += 1
            continue
        recommended = str(decision.get("recommended_option", ""))
        chosen = str(decision.get("chosen_option", ""))
        if not recommended or recommended != chosen:
            skipped_not_recommended += 1
            continue
        kind = str(ticket.get("stream", "") or "general")
        chosen_text = option_text(decision, chosen)
        key = (risk, kind, recommended, chosen, chosen_text)
        groups[key].append(
            {
                "decision": decision.get("id", decision_path.stem),
                "decision_title": decision.get("title", ""),
                "decision_file": str(decision_path.relative_to(root)),
                "ticket": ticket_id,
                "ticket_file": str(ticket_path.relative_to(root)),
                "linked_outcomes": outcomes.get(ticket_id, []) + outcomes.get(str(decision.get("id", "")), []),
            }
        )

    candidates: list[dict[str, Any]] = []
    for (risk, kind, recommended, chosen, chosen_text), items in sorted(groups.items()):
        count = len(items)
        if count < 3:
            continue
        policy_kind = slug_token(kind)
        policy_id = f"POL-{policy_kind}-{risk}-AUTO"
        title = candidate_title(kind, risk)
        hgl_reduction = count * HGL_WEIGHTS.get(risk, 1)
        linked_outcomes: list[dict[str, str]] = []
        seen_outcomes: set[str] = set()
        for item in items:
            for outcome in item["linked_outcomes"]:
                if outcome["id"] in seen_outcomes:
                    continue
                seen_outcomes.add(outcome["id"])
                linked_outcomes.append(outcome)
        candidates.append(
            {
                "id": policy_id,
                "title": title,
                "risk": risk,
                "kind": kind,
                "decision_count": count,
                "recommended_option": recommended,
                "chosen_option": chosen,
                "chosen_text": chosen_text,
                "suggested_mode": "simulation",
                "expected_hgl_reduction": hgl_reduction,
                "linked_outcome_count": len(linked_outcomes),
                "linked_outcomes": linked_outcomes,
                "observed": (
                    f"{count} decided {risk} {kind} decisions, "
                    f"{count} chose recommended option {chosen}"
                ),
                "next_command": (
                    f'./bin/palari policy create {policy_id} "{title}" '
                    f"--risk-max {risk} --mode simulation"
                ),
                "examples": items[:5],
            }
        )

    return {
        "simulation_only": True,
        "created_policy_files": False,
        "inspected_decisions": inspected,
        "candidate_count": len(candidates),
        "skipped": {
            "high_risk_or_governance": skipped_high_risk,
            "missing_ticket": skipped_no_ticket,
            "not_matching_recommendation": skipped_not_recommended,
        },
        "candidates": candidates,
    }


def text_report(data: dict[str, Any]) -> str:
    lines = [
        "Policy candidates",
        "Mode: suggestions only; no policy files were created or activated.",
        f"Inspected decided decisions: {data['inspected_decisions']}",
        "",
    ]
    if not data["candidates"]:
        lines.append("No conservative policy candidates found.")
        lines.append("Need at least 3 repeated R0-R2 decisions with the same recommended and chosen option.")
        return "\n".join(lines) + "\n"
    for candidate in data["candidates"]:
        lines.extend(
            [
                f"Policy candidate: {candidate['title']}",
                f"Observed: {candidate['observed']}",
                "Suggested mode: simulation",
                f"Expected HGL reduction: {candidate['expected_hgl_reduction']}",
                f"Linked outcomes: {candidate['linked_outcome_count']} recorded",
                f"Next: {candidate['next_command']}",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--tickets-open-dir", required=True)
    parser.add_argument("--tickets-closed-dir", required=True)
    parser.add_argument("--decisions-decided-dir", required=True)
    parser.add_argument("--outcomes-recorded-dir", required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    data = build_candidates(Path(args.root), args)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(text_report(data), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
