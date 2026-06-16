#!/usr/bin/env python3
"""Read-only minimum viable human company planner."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
from dataclasses import dataclass, field
from types import SimpleNamespace
from typing import Any

import hgl
from artifacts import md_files


@dataclass
class Requirement:
    skill: str
    level: str
    role: str
    risk: str
    workflows: set[str] = field(default_factory=set)
    decision_count: int = 0
    covered_by: set[str] = field(default_factory=set)

    def as_dict(self) -> dict[str, Any]:
        covered = sorted(self.covered_by)
        if not covered:
            status = "missing"
        elif len(covered) == 1:
            status = "thin"
        else:
            status = "covered"
        return {
            "role": self.role,
            "skill": self.skill,
            "level": self.level,
            "risk": self.risk,
            "workflow_count": len(self.workflows),
            "decision_count": self.decision_count,
            "covered_by": covered,
            "status": status,
            "recommendation": recommendation_for(self.role, self.skill, self.level, self.risk, status),
        }


def role_for_skill(skill: str) -> str:
    lowered = skill.lower()
    if "privacy" in lowered:
        return "privacy_governor"
    if "security" in lowered or "technical" in lowered or "engineering" in lowered:
        return "technical_governor"
    if "customer" in lowered or "brand" in lowered or "support" in lowered:
        return "customer_brand_governor"
    if "analytics" in lowered or "data" in lowered:
        return "analytics_reviewer"
    if "operations" in lowered or "ops" in lowered:
        return "operations_governor"
    if "product" in lowered or "growth" in lowered:
        return "product_governor"
    cleaned = re.sub(r"[^a-z0-9]+", "_", lowered).strip("_")
    return f"{cleaned or 'general'}_governor"


def recommendation_for(role: str, skill: str, level: str, risk: str, status: str) -> str:
    if status == "missing":
        return f"add {role} with {skill} {level} and {risk} authority or reduce workflow scope"
    if status == "thin":
        return f"add backup coverage for {role} before relying on high-risk autonomy"
    return f"keep {role} coverage current and watch capacity"


def workflow_rows(root: pathlib.Path, args: argparse.Namespace) -> list[tuple[Any, dict[str, Any]]]:
    rows: list[tuple[Any, dict[str, Any]]] = []
    for path in md_files(root, args.workflows_active_dir):
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
            rows.append((artifact, hgl.analyze(root, hgl_args)))
        except (OSError, ValueError, SystemExit):
            continue
    return rows


def merge_requirement(
    requirements: dict[tuple[str, str, str, str], Requirement],
    workflow_id: str,
    risk: str,
    coverage: dict[str, Any],
) -> None:
    skill = str(coverage["skill"])
    level = str(coverage["level"])
    role = role_for_skill(skill)
    key = (role, skill, level, risk)
    existing = requirements.get(key)
    if existing is None:
        existing = Requirement(skill=skill, level=level, role=role, risk=risk)
        requirements[key] = existing
    existing.workflows.add(workflow_id)
    existing.decision_count += 1
    existing.covered_by.update(str(human) for human in coverage.get("covered_by", []))


def concentration_risks(requirements: list[dict[str, Any]]) -> list[dict[str, Any]]:
    coverage: dict[str, list[dict[str, Any]]] = {}
    for requirement in requirements:
        for human in requirement["covered_by"]:
            coverage.setdefault(human, []).append(requirement)
    risks: list[dict[str, Any]] = []
    for human, covered in sorted(coverage.items()):
        high_risk = [item for item in covered if hgl.risk_number(str(item["risk"])) >= 3]
        if len(covered) >= 3 or len(high_risk) >= 2:
            roles = sorted({str(item["role"]) for item in covered})
            risks.append(
                {
                    "human": human,
                    "covered_requirement_count": len(covered),
                    "high_risk_requirement_count": len(high_risk),
                    "roles": roles,
                    "message": f"{human} covers {len(covered)} required governance role(s)",
                }
            )
    return risks


def build_plan(root: pathlib.Path, args: argparse.Namespace) -> dict[str, Any]:
    root = root.resolve()
    workflows = workflow_rows(root, args)
    requirements: dict[tuple[str, str, str, str], Requirement] = {}
    for _, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        for decision in data.get("decisions", []):
            risk = str(decision.get("risk", "R0"))
            for coverage in decision.get("coverage", []):
                merge_requirement(requirements, workflow_id, risk, coverage)
    rows = sorted(
        [requirement.as_dict() for requirement in requirements.values()],
        key=lambda item: (
            -hgl.risk_number(str(item["risk"])),
            item["status"] != "missing",
            item["role"],
            item["skill"],
        ),
    )
    missing = [item for item in rows if item["status"] == "missing"]
    thin = [item for item in rows if item["status"] == "thin"]
    if missing:
        recommendation = missing[0]["recommendation"]
    elif thin:
        recommendation = thin[0]["recommendation"]
    elif rows:
        recommendation = "current active workflows have minimum human coverage; keep capacity and evidence current"
    else:
        recommendation = "no active workflow requirements found"
    return {
        "active_workflow_count": len(workflows),
        "requirements": rows,
        "missing_requirements": len(missing),
        "thin_requirements": len(thin),
        "concentration_risks": concentration_risks(rows),
        "recommendation": recommendation,
    }


def print_text(data: dict[str, Any]) -> None:
    print("Minimum viable human company for active workflows:")
    if not data["requirements"]:
        print("- (none)")
    for item in data["requirements"]:
        covered = ", ".join(item["covered_by"]) if item["covered_by"] else "missing"
        print(
            f"- {item['role']} {item['level']}: {item['skill']} for {item['risk']} "
            f"({item['status']}; {covered})"
        )
    print()
    print("Concentration risk:")
    if not data["concentration_risks"]:
        print("- (none)")
    for item in data["concentration_risks"]:
        print(f"- {item['message']}: {', '.join(item['roles'])}")
    print()
    print("Recommendation:")
    print(f"- {data['recommendation']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--workflows-proposed-dir", required=True)
    parser.add_argument("--workflows-active-dir", required=True)
    parser.add_argument("--workflows-closed-dir", required=True)
    parser.add_argument("--humans-active-dir", required=True)
    args = parser.parse_args()
    data = build_plan(pathlib.Path(args.root), args)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print_text(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
