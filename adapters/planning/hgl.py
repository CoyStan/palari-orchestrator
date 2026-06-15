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
    authority_max_risk: str
    may_approve_policy_changes: bool
    current_weekly_hgl: int
    weekly_hgl_budget: int
    max_concurrent_r3: int
    current_open_r3: int
    max_concurrent_r4: int
    current_open_r4: int
    max_concurrent_r5: int
    current_open_r5: int


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


def risk_number(value: str) -> int:
    match = re.fullmatch(r"R([0-5])", value.strip())
    return int(match.group(1)) if match else -1


def bool_field(value: str) -> bool:
    return value.strip().lower() == "true"


def int_field(fields: dict[str, str], key: str, default: int) -> int:
    try:
        value = fields.get(key, "")
        return int(value) if value != "" else default
    except ValueError:
        return default


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
        weekly_budget = int_field(
            artifact.fields,
            "weekly_hgl_budget",
            int_field(artifact.fields, "capacity_weekly_hgl", 0),
        )
        # Legacy capacity_open_rN values were written as 0 by early profile
        # templates, so a legacy zero means "unspecified" rather than no
        # capacity. Explicit max_concurrent_rN fields are authoritative.
        max_r3 = int_field(
            artifact.fields,
            "max_concurrent_r3",
            max(1, int_field(artifact.fields, "capacity_open_r3", 6)),
        )
        max_r4 = int_field(
            artifact.fields,
            "max_concurrent_r4",
            max(1, int_field(artifact.fields, "capacity_open_r4", 2)),
        )
        max_r5 = int_field(
            artifact.fields,
            "max_concurrent_r5",
            max(1, int_field(artifact.fields, "capacity_open_r5", 1)),
        )
        humans.append(
            Human(
                artifact=artifact,
                skills=skills,
                roles=artifact.lists.get("roles", []),
                authority_max_risk=artifact.fields.get("authority_max_risk", "R0") or "R0",
                may_approve_policy_changes=bool_field(
                    artifact.fields.get("may_approve_policy_changes", "false")
                ),
                current_weekly_hgl=int_field(artifact.fields, "current_weekly_hgl", 0),
                weekly_hgl_budget=weekly_budget,
                max_concurrent_r3=max_r3,
                current_open_r3=int_field(artifact.fields, "current_open_r3", 0),
                max_concurrent_r4=max_r4,
                current_open_r4=int_field(artifact.fields, "current_open_r4", 0),
                max_concurrent_r5=max_r5,
                current_open_r5=int_field(artifact.fields, "current_open_r5", 0),
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


def parse_work_unit(item: str) -> dict[str, str]:
    parts = item.split("|")
    while len(parts) < 4:
        parts.append("")
    unit_id, kind, risk, title = parts[:4]
    return {"id": unit_id, "kind": kind, "risk": risk, "title": title, "raw": item}


def max_risk(values: list[str]) -> str:
    valid = [value for value in values if risk_number(value) >= 0]
    if not valid:
        return "R0"
    return max(valid, key=risk_number)


def has_expected_risk_at_least(counts: dict[str, int], risk: str) -> bool:
    threshold = risk_number(risk)
    return any(risk_number(item) >= threshold and count > 0 for item, count in counts.items())


def risk_coverage_gaps(
    workflow_risk_ceiling: str, work_units: list[dict[str, str]], counts: dict[str, int]
) -> list[str]:
    gaps: list[str] = []
    if risk_number(workflow_risk_ceiling) >= 4 and not has_expected_risk_at_least(
        counts, workflow_risk_ceiling
    ):
        gaps.append(
            f"workflow risk ceiling {workflow_risk_ceiling} has no expected decision at or above that risk"
        )
    for unit in work_units:
        risk = unit.get("risk", "")
        if risk_number(risk) >= 4 and not has_expected_risk_at_least(counts, risk):
            gaps.append(
                f"work unit {unit.get('id', '(unknown)')} {risk} has no expected decision at or above that risk"
            )
    return sorted(set(gaps))


def human_id(human: Human) -> str:
    return human.artifact.fields.get("id", "")


def human_can_cover_risk(human: Human, risk: str) -> bool:
    return risk_number(human.authority_max_risk) >= risk_number(risk)


def human_at_risk_capacity(human: Human, risk: str) -> bool:
    if risk == "R3":
        return human.current_open_r3 >= human.max_concurrent_r3
    if risk == "R4":
        return human.current_open_r4 >= human.max_concurrent_r4
    if risk == "R5":
        return human.current_open_r5 >= human.max_concurrent_r5
    return False


def coverage_failure(skill: str, level: int, decision_risk: str, row: dict[str, object]) -> str:
    label = f"{skill}:L{level}"
    if row["under_authorized"]:
        return f"{label} has candidates but none with {decision_risk} authority"
    if row["at_capacity"]:
        return f"{label} has authorized candidates but all are at risk capacity"
    if row["underleveled"]:
        return f"{label} has humans with the skill but below the required level"
    return f"{label} has no active human candidates"


def coverage_for(
    required: list[tuple[str, int]], humans: list[Human], decision_risk: str
) -> tuple[list[dict[str, object]], str]:
    rows: list[dict[str, object]] = []
    scarcity = "covered_by_two_or_more"
    for skill, level in required:
        covering: list[Human] = []
        under_authorized: list[Human] = []
        underleveled: list[Human] = []
        at_capacity: list[Human] = []
        for human in humans:
            human_level = human.skills.get(skill, 0)
            if human_level == 0:
                continue
            if human_level < level:
                underleveled.append(human)
                continue
            if not human_can_cover_risk(human, decision_risk):
                under_authorized.append(human)
                continue
            if decision_risk == "R5" and not human.may_approve_policy_changes:
                under_authorized.append(human)
                continue
            if human_at_risk_capacity(human, decision_risk):
                at_capacity.append(human)
                continue
            covering.append(human)
        rows.append(
            {
                "skill": skill,
                "level": f"L{level}",
                "covered_by": [human_id(human) for human in covering],
                "under_authorized": [human_id(human) for human in under_authorized],
                "underleveled": [human_id(human) for human in underleveled],
                "at_capacity": [human_id(human) for human in at_capacity],
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
        * factor
    )
    return int(math.ceil(value))


def analyze(root: pathlib.Path, args: argparse.Namespace) -> dict[str, object]:
    workflow = find_artifact(
        root,
        [args.workflows_active_dir, args.workflows_proposed_dir, args.workflows_closed_dir],
        args.workflow,
    )
    humans = load_active_humans(root, args.humans_active_dir)
    workflow_risk_ceiling = workflow.fields.get("risk_ceiling", "R0") or "R0"
    work_units = [parse_work_unit(item) for item in workflow.lists.get("work_units", [])]
    decisions = [parse_decision(item) for item in workflow.lists.get("expected_decisions", [])]
    counts = {risk: 0 for risk in RISKS}
    decision_rows: list[dict[str, object]] = []
    missing_skills: set[str] = set()
    coverage_failures: set[str] = set()
    risk_capacity_failures: set[str] = set()
    bottlenecks: set[str] = set()
    total = 0
    red = False
    yellow = False

    for decision in decisions:
        risk = str(decision["risk"])
        if risk in counts:
            counts[risk] += 1
        coverage, scarcity = coverage_for(
            decision["required"], humans, risk  # type: ignore[arg-type]
        )
        for row in coverage:
            covered = row["covered_by"]
            if not covered:
                missing_skills.add(f"{row['skill']}:{row['level']}")
                coverage_failures.add(
                    coverage_failure(str(row["skill"]), level_number(str(row["level"])), risk, row)
                )
            elif isinstance(covered, list) and len(covered) == 1:
                for role in row.get("roles", []):  # type: ignore[union-attr]
                    bottlenecks.add(str(role))
            for human in row.get("at_capacity", []):  # type: ignore[union-attr]
                risk_capacity_failures.add(f"{human} at {risk} capacity")
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

    max_work_unit_risk = max_risk([unit.get("risk", "R0") for unit in work_units])
    max_expected_decision_risk = max_risk([str(decision["risk"]) for decision in decisions])
    max_declared_risk = max_risk(
        [workflow_risk_ceiling, max_work_unit_risk, max_expected_decision_risk]
    )
    risk_sources = {
        "workflow_risk_ceiling": workflow_risk_ceiling,
        "max_work_unit_risk": max_work_unit_risk,
        "max_expected_decision_risk": max_expected_decision_risk,
        "max_declared_risk": max_declared_risk,
    }
    planning_gaps = risk_coverage_gaps(workflow_risk_ceiling, work_units, counts)
    if planning_gaps:
        if risk_number(max_declared_risk) >= 4:
            red = True
        elif risk_number(max_declared_risk) == 3:
            yellow = True

    capacity = sum(human.weekly_hgl_budget for human in humans)
    current_weekly_hgl = sum(human.current_weekly_hgl for human in humans)
    available_weekly_hgl = sum(
        max(0, human.weekly_hgl_budget - human.current_weekly_hgl) for human in humans
    )
    if total > 0 and available_weekly_hgl <= 0:
        red = True
    elif total > available_weekly_hgl:
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
    elif risk_number(max_declared_risk) >= 5:
        autonomy = (
            "human_led"
            if workflow.fields.get("autonomy_target") == "human_led"
            and has_expected_risk_at_least(counts, "R5")
            else "simulation_only"
        )
    elif risk_number(max_declared_risk) >= 4:
        autonomy = "human_led"
    elif risk_number(max_declared_risk) >= 3:
        autonomy = "conditional_autonomy"
    elif risk_number(max_declared_risk) >= 2:
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
        "coverage_failures": sorted(coverage_failures),
        "bottlenecks": sorted(bottlenecks),
        "risk_sources": risk_sources,
        "risk_coverage_gaps": planning_gaps,
        "launch_gate": gate,
        "autonomy_ceiling": autonomy,
        "capacity_weekly_hgl": capacity,
        "capacity": {
            "weekly_hgl_budget": capacity,
            "current_weekly_hgl": current_weekly_hgl,
            "available_weekly_hgl": available_weekly_hgl,
            "risk_capacity_failures": sorted(risk_capacity_failures),
        },
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
    print("coverage_failures:")
    for item in data["coverage_failures"] or ["(none)"]:  # type: ignore[operator]
        print(f"  - {item}")
    print("bottlenecks:")
    for item in data["bottlenecks"] or ["(none)"]:  # type: ignore[operator]
        print(f"  - {item}")
    print("risk_sources:")
    for key, value in data["risk_sources"].items():  # type: ignore[union-attr]
        print(f"  {key}: {value}")
    print("risk_coverage_gaps:")
    for item in data["risk_coverage_gaps"] or ["(none)"]:  # type: ignore[operator]
        print(f"  - {item}")
    print("capacity:")
    capacity = data["capacity"]  # type: ignore[assignment]
    print(f"  weekly_hgl_budget: {capacity['weekly_hgl_budget']}")
    print(f"  current_weekly_hgl: {capacity['current_weekly_hgl']}")
    print(f"  available_weekly_hgl: {capacity['available_weekly_hgl']}")
    print("  risk_capacity_failures:")
    for item in capacity["risk_capacity_failures"] or ["(none)"]:
        print(f"    - {item}")
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
