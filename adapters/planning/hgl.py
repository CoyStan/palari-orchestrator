#!/usr/bin/env python3
"""Deterministic Human Governance Load scoring for Palari workflows."""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
import sys
from dataclasses import dataclass


RISKS = ["R0", "R1", "R2", "R3", "R4", "R5"]
RISK_WEIGHT = {"R0": 0, "R1": 0.25, "R2": 1, "R3": 3, "R4": 8, "R5": 20}
WEIGHTS = {
    "novelty": {"low": 0.8, "medium": 1.0, "high": 1.5},
    "ambiguity": {"low": 0.8, "medium": 1.0, "high": 1.5},
    "irreversibility": {"low": 0.7, "medium": 1.0, "high": 1.7},
    "context": {"low": 0.8, "medium": 1.0, "high": 1.4},
    "evidence": {"none_or_unknown": 1.25, "weak": 1.15, "normal": 1.0, "strong": 0.8},
}


@dataclass(frozen=True)
class Artifact:
    path: pathlib.Path
    fields: dict[str, str]
    lists: dict[str, list[str]]


@dataclass(frozen=True)
class Human:
    artifact: Artifact
    skills: dict[str, int]
    roles: list[str]
    capacity_hgl: int


def parse_frontmatter(path: pathlib.Path) -> Artifact:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError(f"{path}: missing frontmatter")
    end = text.find("\n---", 4)
    if end == -1:
        raise ValueError(f"{path}: unterminated frontmatter")
    fields: dict[str, str] = {}
    lists: dict[str, list[str]] = {}
    current_list: str | None = None
    for raw in text[4:end].splitlines():
        if not raw.strip():
            continue
        if raw.startswith("  - ") and current_list:
            value = raw[4:].strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
                value = value[1:-1]
            lists[current_list].append(value)
            continue
        current_list = None
        if ":" not in raw:
            continue
        key, value = raw.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            fields[key] = ""
            lists.setdefault(key, [])
            current_list = key
        else:
            if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
                value = value[1:-1]
            fields[key] = value
    return Artifact(path=path, fields=fields, lists=lists)


def find_artifact(root: pathlib.Path, dirs: list[str], artifact_id: str) -> Artifact:
    for rel in dirs:
        directory = root / rel
        if not directory.exists():
            continue
        for path in sorted(directory.glob("*.md")):
            artifact = parse_frontmatter(path)
            if artifact.fields.get("id") == artifact_id:
                return artifact
    raise SystemExit(f"artifact not found: {artifact_id}")


def artifacts_in_dir(root: pathlib.Path, rel: str) -> list[Artifact]:
    directory = root / rel
    if not directory.exists():
        return []
    return [parse_frontmatter(path) for path in sorted(directory.glob("*.md"))]


def level_number(value: str) -> int:
    match = re.fullmatch(r"L([1-5])", value.strip())
    return int(match.group(1)) if match else 0


def parse_skill(value: str) -> tuple[str, int] | None:
    if ":" not in value:
        return None
    skill, level = value.rsplit(":", 1)
    parsed = level_number(level)
    if not skill or parsed == 0:
        return None
    return skill, parsed


def load_active_humans(root: pathlib.Path, active_dir: str) -> list[Human]:
    humans: list[Human] = []
    for artifact in artifacts_in_dir(root, active_dir):
        if artifact.fields.get("status") != "active":
            continue
        skills: dict[str, int] = {}
        for item in artifact.lists.get("skills", []):
            parsed = parse_skill(item)
            if parsed:
                skill, level = parsed
                skills[skill] = max(skills.get(skill, 0), level)
        try:
            capacity = int(artifact.fields.get("capacity_weekly_hgl", "0") or "0")
        except ValueError:
            capacity = 0
        humans.append(
            Human(
                artifact=artifact,
                skills=skills,
                roles=artifact.lists.get("roles", []),
                capacity_hgl=capacity,
            )
        )
    return humans


def parse_attrs(parts: list[str]) -> dict[str, str]:
    attrs: dict[str, str] = {}
    for part in parts:
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        attrs[key.strip()] = value.strip()
    return attrs


def parse_decision(item: str) -> dict[str, object]:
    parts = item.split("|")
    while len(parts) < 4:
        parts.append("")
    risk, kind, skills_text, title = parts[:4]
    required: list[tuple[str, int]] = []
    for raw in re.split(r",\s*", skills_text):
        parsed = parse_skill(raw)
        if parsed:
            required.append(parsed)
    return {
        "risk": risk,
        "kind": kind,
        "required": required,
        "title": title,
        "attrs": parse_attrs(parts[4:]),
        "raw": item,
    }


def coverage_for(required: list[tuple[str, int]], humans: list[Human]) -> tuple[list[dict[str, object]], str]:
    rows: list[dict[str, object]] = []
    scarcity = "covered_by_two_or_more"
    for skill, level in required:
        covering = [
            human
            for human in humans
            if human.skills.get(skill, 0) >= level
        ]
        rows.append(
            {
                "skill": skill,
                "level": f"L{level}",
                "covered_by": [human.artifact.fields.get("id", "") for human in covering],
                "roles": sorted({role for human in covering for role in human.roles}),
            }
        )
        if not covering:
            scarcity = "missing_or_underleveled"
        elif len(covering) == 1 and scarcity != "missing_or_underleveled":
            scarcity = "covered_by_one"
    if not required:
        scarcity = "missing_or_underleveled"
    return rows, scarcity


def decision_score(risk: str, attrs: dict[str, str], scarcity: str) -> int:
    if risk not in RISK_WEIGHT:
        return 0
    evidence = attrs.get("evidence", "normal")
    factor = WEIGHTS["evidence"].get(evidence, WEIGHTS["evidence"]["normal"])
    value = (
        RISK_WEIGHT[risk]
        * WEIGHTS["novelty"].get(attrs.get("novelty", "medium"), 1.0)
        * WEIGHTS["ambiguity"].get(attrs.get("ambiguity", "medium"), 1.0)
        * WEIGHTS["irreversibility"].get(attrs.get("irreversibility", "medium"), 1.0)
        * WEIGHTS["context"].get(attrs.get("context", "medium"), 1.0)
        * {"covered_by_two_or_more": 0.8, "covered_by_one": 1.0, "missing_or_underleveled": 1.8}[scarcity]
        / factor
    )
    return int(math.ceil(value))


def analyze(root: pathlib.Path, args: argparse.Namespace) -> dict[str, object]:
    workflow = find_artifact(
        root,
        [args.workflows_active_dir, args.workflows_proposed_dir, args.workflows_closed_dir],
        args.workflow,
    )
    humans = load_active_humans(root, args.humans_active_dir)
    decisions = [parse_decision(item) for item in workflow.lists.get("expected_decisions", [])]
    counts = {risk: 0 for risk in RISKS}
    decision_rows: list[dict[str, object]] = []
    missing_skills: set[str] = set()
    bottlenecks: set[str] = set()
    total = 0
    red = False
    yellow = False

    for decision in decisions:
        risk = str(decision["risk"])
        if risk in counts:
            counts[risk] += 1
        coverage, scarcity = coverage_for(decision["required"], humans)  # type: ignore[arg-type]
        for row in coverage:
            covered = row["covered_by"]
            if not covered:
                missing_skills.add(f"{row['skill']}:{row['level']}")
            elif isinstance(covered, list) and len(covered) == 1:
                for role in row.get("roles", []):  # type: ignore[union-attr]
                    bottlenecks.add(str(role))
        score = decision_score(risk, decision["attrs"], scarcity)  # type: ignore[arg-type]
        total += score
        if risk in {"R4", "R5"} and scarcity == "missing_or_underleveled":
            red = True
        if risk in {"R3", "R4"} and scarcity == "covered_by_one":
            yellow = True
        if risk == "R5":
            has_l5_coverage = any(
                row["level"] == "L5" and row["covered_by"] for row in coverage
            )
            if not has_l5_coverage:
                red = True
        decision_rows.append(
            {
                "risk": risk,
                "kind": decision["kind"],
                "title": decision["title"],
                "score": score,
                "skill_scarcity": scarcity,
                "coverage": coverage,
            }
        )

    capacity = sum(human.capacity_hgl for human in humans)
    if capacity and total > capacity:
        yellow = True
    if missing_skills and any(counts[risk] for risk in ["R3", "R4", "R5"]):
        red = True

    if red:
        gate = "red"
    elif yellow:
        gate = "yellow"
    else:
        gate = "green"

    if gate == "red":
        autonomy = "simulation_only"
    elif counts["R4"] or counts["R5"]:
        autonomy = "human_led"
    elif counts["R3"]:
        autonomy = "conditional_autonomy"
    elif counts["R2"]:
        autonomy = "high_autonomy"
    else:
        autonomy = "full_autonomy"

    required_skills: dict[str, str] = {}
    for decision in decisions:
        for skill, level in decision["required"]:  # type: ignore[index]
            current = level_number(required_skills.get(skill, "L0"))
            if level > current:
                required_skills[skill] = f"L{level}"

    return {
        "workflow": workflow.fields.get("id", args.workflow),
        "title": workflow.fields.get("title", ""),
        "human_governance_load": total,
        "expected_decisions": counts,
        "required_skills": dict(sorted(required_skills.items())),
        "missing_skills": sorted(missing_skills),
        "bottlenecks": sorted(bottlenecks),
        "launch_gate": gate,
        "autonomy_ceiling": autonomy,
        "capacity_weekly_hgl": capacity,
        "decisions": decision_rows,
    }


def print_text(data: dict[str, object], coverage_only: bool) -> None:
    print(f"workflow: {data['workflow']}")
    print(f"title: {data['title']}")
    if not coverage_only:
        print(f"human_governance_load: {data['human_governance_load']}")
    print("expected_decisions:")
    for risk, count in (data["expected_decisions"]).items():  # type: ignore[union-attr]
        print(f"  {risk}: {count}")
    print("required_skills:")
    skills = data["required_skills"]  # type: ignore[assignment]
    if skills:
        for skill, level in skills.items():
            print(f"  {skill}: {level}")
    else:
        print("  (none)")
    print("missing_skills:")
    for item in data["missing_skills"] or ["(none)"]:  # type: ignore[operator]
        print(f"  - {item}")
    print("bottlenecks:")
    for item in data["bottlenecks"] or ["(none)"]:  # type: ignore[operator]
        print(f"  - {item}")
    print(f"launch_gate: {data['launch_gate']}")
    print(f"autonomy_ceiling: {data['autonomy_ceiling']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--workflow", required=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--coverage-only", action="store_true")
    parser.add_argument("--workflows-proposed-dir", required=True)
    parser.add_argument("--workflows-active-dir", required=True)
    parser.add_argument("--workflows-closed-dir", required=True)
    parser.add_argument("--humans-active-dir", required=True)
    args = parser.parse_args()
    data = analyze(pathlib.Path(args.root), args)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print_text(data, args.coverage_only)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

