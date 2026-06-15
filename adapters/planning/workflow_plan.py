#!/usr/bin/env python3
"""Read-only workflow planning composed from workflow and HGL artifacts."""

from __future__ import annotations

import argparse
import json
import pathlib
from types import SimpleNamespace
from typing import Any

import hgl


HIGH_RISK_MODES = {
    "production_write_without_human",
    "customer_send_without_human",
    "billing_change",
    "policy_accept_without_human",
}
RED_SAFE_MODES = {"research"}


def list_or_default(items: list[str], default: list[str]) -> list[str]:
    return items if items else default


def covered_skill_rows(hgl_data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for skill, level in hgl_data["required_skills"].items():
        rows[skill] = {"level": level, "covered_by": [], "roles": []}
    for decision in hgl_data["decisions"]:
        for coverage in decision["coverage"]:
            skill = coverage["skill"]
            entry = rows.setdefault(
                skill,
                {"level": coverage["level"], "covered_by": [], "roles": []},
            )
            if hgl.level_number(coverage["level"]) > hgl.level_number(entry["level"]):
                entry["level"] = coverage["level"]
            entry["covered_by"] = sorted(
                set(entry["covered_by"]) | set(coverage.get("covered_by", []))
            )
            entry["roles"] = sorted(set(entry["roles"]) | set(coverage.get("roles", [])))
    return dict(sorted(rows.items()))


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


def why_human_needed(
    risk: str, required_skills: dict[str, str], status: str
) -> list[str]:
    reasons: list[str] = []
    if risk == "R5":
        reasons.extend(["R5 governance decision", "no policy acceptance allowed"])
    elif risk == "R4":
        reasons.append("R4 company-impact decision")
    elif risk == "R3":
        reasons.append("R3 human judgment decision")
    else:
        reasons.append("declared expected human decision")
    for skill, level in sorted(required_skills.items()):
        reasons.append(f"required skill: {skill} {level}")
    if status == "missing_authorized_human":
        reasons.append("authorized human coverage missing")
    elif status == "at_capacity":
        reasons.append("qualified human coverage is at capacity")
    elif status == "underleveled":
        reasons.append("available human skill is below required level")
    elif status == "missing_skill":
        reasons.append("active human skill coverage missing")
    return reasons


def human_decision_map(hgl_data: dict[str, Any]) -> list[dict[str, Any]]:
    decisions: list[dict[str, Any]] = []
    for decision in hgl_data["decisions"]:
        coverage_rows = list(decision.get("coverage", []))
        required_skills = {
            str(row["skill"]): str(row["level"])
            for row in coverage_rows
            if row.get("skill") and row.get("level")
        }
        eligible_humans = sorted(
            {
                str(human)
                for row in coverage_rows
                for human in row.get("covered_by", [])
            }
        )
        status = coverage_status(coverage_rows)
        risk = str(decision["risk"])
        decisions.append(
            {
                "risk": risk,
                "kind": decision["kind"],
                "title": decision["title"],
                "hgl_score": decision["score"],
                "required_skills": dict(sorted(required_skills.items())),
                "eligible_humans": eligible_humans,
                "coverage_status": status,
                "why_human_needed": why_human_needed(risk, required_skills, status),
            }
        )
    return sorted(
        decisions,
        key=lambda item: (
            -hgl.risk_number(str(item["risk"])),
            -int(item["hgl_score"]),
            str(item["title"]),
        ),
    )


def allowed_modes_for_gate(allowed_modes: list[str], gate: str) -> list[str]:
    if gate == "red":
        return [mode for mode in allowed_modes if mode in RED_SAFE_MODES]
    return [mode for mode in allowed_modes if mode not in HIGH_RISK_MODES]


def blocked_modes_for_gate(allowed_modes: list[str], forbidden_modes: list[str], gate: str) -> list[str]:
    blocked = set(forbidden_modes)
    if gate == "red":
        blocked.update(mode for mode in allowed_modes if mode not in RED_SAFE_MODES)
    return sorted(blocked)


def recommendations(plan: dict[str, Any]) -> list[str]:
    actions: list[str] = []
    for item in plan["missing_skills"]:
        skill, _, level = item.partition(":")
        actions.append(f"create or assign {skill} {level} coverage")
    for role in plan["bottlenecks"]:
        actions.append(f"add backup coverage for bottleneck role {role}")
    for gap in plan.get("risk_coverage_gaps", []):
        actions.append(f"add expected human decision coverage: {gap}")
    for failure in plan.get("capacity", {}).get("risk_capacity_failures", []):
        actions.append(f"reduce or reassign capacity bottleneck: {failure}")
    if plan.get("capacity", {}).get("available_weekly_hgl", 0) < plan["human_governance_load"]:
        actions.append("reduce scope or add weekly HGL capacity before launch")
    if plan["launch_gate"] == "red":
        actions.append("keep the workflow in research or simulation until coverage improves")
    if plan["expected_decisions"].get("R4", 0) or plan["expected_decisions"].get("R5", 0):
        actions.append("require explicit human approval for company-impacting gates")
    if not actions:
        actions.append("keep evidence current and proceed within the declared workflow modes")
    return actions


def build_plan(root: pathlib.Path, args: argparse.Namespace) -> dict[str, Any]:
    workflow_args = SimpleNamespace(
        workflow=args.workflow,
        workflows_proposed_dir=args.workflows_proposed_dir,
        workflows_active_dir=args.workflows_active_dir,
        workflows_closed_dir=args.workflows_closed_dir,
        humans_active_dir=args.humans_active_dir,
    )
    workflow = hgl.find_artifact(
        root,
        [args.workflows_active_dir, args.workflows_proposed_dir, args.workflows_closed_dir],
        args.workflow,
    )
    hgl_data = hgl.analyze(root, workflow_args)
    allowed_modes = list_or_default(workflow.lists.get("allowed_modes", []), ["research", "draft"])
    forbidden_modes = workflow.lists.get("forbidden_modes", [])
    gate = hgl_data["launch_gate"]
    plan: dict[str, Any] = {
        "workflow": hgl_data["workflow"],
        "title": hgl_data["title"],
        "goal": workflow.fields.get("goal", ""),
        "status": workflow.fields.get("status", ""),
        "risk_ceiling": workflow.fields.get("risk_ceiling", ""),
        "launch_gate": gate,
        "autonomy_ceiling": hgl_data["autonomy_ceiling"],
        "ai_can_proceed": allowed_modes_for_gate(allowed_modes, gate),
        "ai_must_not_proceed": blocked_modes_for_gate(allowed_modes, forbidden_modes, gate),
        "human_governance_load": hgl_data["human_governance_load"],
        "expected_decisions": hgl_data["expected_decisions"],
        "human_decision_map": human_decision_map(hgl_data),
        "required_skills": covered_skill_rows(hgl_data),
        "missing_skills": hgl_data["missing_skills"],
        "bottlenecks": hgl_data["bottlenecks"],
        "risk_sources": hgl_data["risk_sources"],
        "risk_coverage_gaps": hgl_data["risk_coverage_gaps"],
        "capacity": hgl_data["capacity"],
        "work_units": workflow.lists.get("work_units", []),
        "guardrails": workflow.lists.get("guardrails", []),
    }
    plan["recommended_next_actions"] = recommendations(plan)
    return plan


def print_list(title: str, items: list[str]) -> None:
    print(f"{title}:")
    if not items:
        print("- (none)")
        return
    for item in items:
        print(f"- {item}")


def print_human_decision_map(items: list[dict[str, Any]]) -> None:
    print("Human decision map:")
    if not items:
        print("- (none)")
        return
    for item in items:
        print(f"- {item['risk']} {item['kind']}: {item['title']}")
        skills = item["required_skills"]
        skill_label = "skills" if len(skills) != 1 else "skill"
        if skills:
            skill_text = ", ".join(f"{skill} {level}" for skill, level in skills.items())
        else:
            skill_text = "(none)"
        print(f"  {skill_label}: {skill_text}")
        print(f"  status: {str(item['coverage_status']).replace('_', ' ')}")
        print(f"  HGL: {item['hgl_score']}")
        eligible = item["eligible_humans"] or ["(none)"]
        print(f"  eligible: {', '.join(eligible)}")
        print(f"  why: {'; '.join(item['why_human_needed'])}")


def print_text(plan: dict[str, Any]) -> None:
    print(f"Workflow: {plan['workflow']} {plan['title']}")
    print(f"Goal: {plan['goal']}")
    print(f"Launch gate: {plan['launch_gate']}")
    print(f"Autonomy ceiling: {plan['autonomy_ceiling']}")
    print()
    print_list("AI can proceed", plan["ai_can_proceed"])
    print()
    print_list("AI must not proceed", plan["ai_must_not_proceed"])
    print()
    print(f"Human Governance Load: {plan['human_governance_load']}")
    for risk, count in plan["expected_decisions"].items():
        print(f"{risk} decisions: {count}")
    print()
    print_human_decision_map(plan["human_decision_map"])
    print()
    print("Required skills:")
    if plan["required_skills"]:
        for skill, data in plan["required_skills"].items():
            covered = data["covered_by"] or ["missing"]
            print(f"- {skill} {data['level']}: covered by {', '.join(covered)}")
    else:
        print("- (none)")
    print()
    print_list("Missing skills", plan["missing_skills"])
    print()
    print_list("Bottlenecks", plan["bottlenecks"])
    print()
    print("Risk sources:")
    for key, value in plan["risk_sources"].items():
        print(f"- {key}: {value}")
    print()
    print_list("Risk coverage gaps", plan["risk_coverage_gaps"])
    print()
    print("Capacity:")
    capacity = plan["capacity"]
    print(f"- weekly_hgl_budget: {capacity['weekly_hgl_budget']}")
    print(f"- current_weekly_hgl: {capacity['current_weekly_hgl']}")
    print(f"- available_weekly_hgl: {capacity['available_weekly_hgl']}")
    print("- risk_capacity_failures:")
    failures = capacity["risk_capacity_failures"] or ["(none)"]
    for item in failures:
        print(f"  - {item}")
    print()
    print_list("Recommended next actions", plan["recommended_next_actions"])
    print()
    print("Note: workflow planning is read-only. It does not claim tickets, run agents, accept work, or perform side effects.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--workflow", required=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--workflows-proposed-dir", required=True)
    parser.add_argument("--workflows-active-dir", required=True)
    parser.add_argument("--workflows-closed-dir", required=True)
    parser.add_argument("--humans-active-dir", required=True)
    args = parser.parse_args()
    plan = build_plan(pathlib.Path(args.root), args)
    if args.json:
        print(json.dumps(plan, indent=2, sort_keys=True))
    else:
        print_text(plan)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
