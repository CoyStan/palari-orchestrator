#!/usr/bin/env python3
"""Read-only Human Governance Debt report for active workflows."""

from __future__ import annotations

import argparse
import json
import pathlib
from dataclasses import dataclass
from types import SimpleNamespace
from typing import Any

import hgl
import policy_candidates
from artifacts import md_files


SEVERITY_ORDER = {"high": 0, "medium": 1, "low": 2}


@dataclass(frozen=True)
class DebtItem:
    severity: str
    category: str
    message: str
    recommendation: str
    workflow: str = ""
    risk: str = ""
    hgl: int = 0

    def as_dict(self) -> dict[str, Any]:
        data: dict[str, Any] = {
            "severity": self.severity,
            "category": self.category,
            "message": self.message,
            "recommendation": self.recommendation,
        }
        if self.workflow:
            data["workflow"] = self.workflow
        if self.risk:
            data["risk"] = self.risk
        if self.hgl:
            data["hgl"] = self.hgl
        return data


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


def policy_candidate_count(root: pathlib.Path, args: argparse.Namespace) -> int:
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


def active_humans(root: pathlib.Path, args: argparse.Namespace) -> list[hgl.Human]:
    return hgl.load_active_humans(root, args.humans_active_dir)


def max_active_risk(workflows: list[tuple[Any, dict[str, Any]]]) -> str:
    return hgl.max_risk(
        [str(data.get("risk_sources", {}).get("max_declared_risk", "R0")) for _, data in workflows]
    )


def missing_skill_items(workflows: list[tuple[Any, dict[str, Any]]]) -> list[DebtItem]:
    by_skill: dict[str, list[str]] = {}
    max_risk_by_skill: dict[str, str] = {}
    for _, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        workflow_risk = str(data.get("risk_sources", {}).get("max_declared_risk", "R0"))
        for skill in data.get("missing_skills", []):
            by_skill.setdefault(str(skill), []).append(workflow_id)
            max_risk_by_skill[str(skill)] = hgl.max_risk(
                [max_risk_by_skill.get(str(skill), "R0"), workflow_risk]
            )
    items: list[DebtItem] = []
    for skill, workflow_ids in sorted(by_skill.items()):
        count = len(sorted(set(workflow_ids)))
        workflow_word = "workflow" if count == 1 else "workflows"
        risk = max_risk_by_skill.get(skill, "R0")
        severity = "high" if hgl.risk_number(risk) >= 4 else "medium"
        items.append(
            DebtItem(
                severity=severity,
                category="missing_skill_coverage",
                message=f"{skill} missing for {count} active {workflow_word}",
                recommendation=f"assign authorized {skill.replace(':', ' ')} coverage or reduce workflow scope",
                risk=risk,
            )
        )
    return items


def bottleneck_items(workflows: list[tuple[Any, dict[str, Any]]]) -> list[DebtItem]:
    by_role: dict[str, list[str]] = {}
    max_risk_by_role: dict[str, str] = {}
    for _, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        workflow_risk = str(data.get("risk_sources", {}).get("max_declared_risk", "R0"))
        for role in data.get("bottlenecks", []):
            by_role.setdefault(str(role), []).append(workflow_id)
            max_risk_by_role[str(role)] = hgl.max_risk(
                [max_risk_by_role.get(str(role), "R0"), workflow_risk]
            )
    items: list[DebtItem] = []
    for role, workflow_ids in sorted(by_role.items()):
        risk = max_risk_by_role.get(role, "R0")
        if hgl.risk_number(risk) < 3:
            continue
        count = len(sorted(set(workflow_ids)))
        severity = "high" if hgl.risk_number(risk) >= 5 else "medium"
        items.append(
            DebtItem(
                severity=severity,
                category="bottleneck",
                message=f"{role} is sole {risk} bottleneck for {count} active workflow(s)",
                recommendation=f"add backup coverage for bottleneck role {role}",
                risk=risk,
            )
        )
    return items


def capacity_items(workflows: list[tuple[Any, dict[str, Any]]], humans: list[hgl.Human]) -> list[DebtItem]:
    items: list[DebtItem] = []
    seen: set[str] = set()
    for _, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        capacity = data.get("capacity", {})
        hgl_total = int(data.get("human_governance_load", 0))
        available = int(capacity.get("available_weekly_hgl", 0))
        if hgl_total > available:
            message = f"{workflow_id} exceeds available weekly HGL"
            if message not in seen:
                seen.add(message)
                items.append(
                    DebtItem(
                        severity="high" if available == 0 else "medium",
                        category="capacity",
                        message=message,
                        recommendation="reduce workflow scope or add weekly HGL capacity",
                        workflow=workflow_id,
                        hgl=hgl_total,
                    )
                )
        for failure in capacity.get("risk_capacity_failures", []):
            message = str(failure)
            if message not in seen:
                seen.add(message)
                items.append(
                    DebtItem(
                        severity="high",
                        category="capacity",
                        message=message,
                        recommendation="reassign the decision or reduce that human's open high-risk load",
                        workflow=workflow_id,
                    )
                )
    for human in humans:
        hid = hgl.human_id(human)
        for risk, current, maximum in [
            ("R3", human.current_open_r3, human.max_concurrent_r3),
            ("R4", human.current_open_r4, human.max_concurrent_r4),
            ("R5", human.current_open_r5, human.max_concurrent_r5),
        ]:
            if maximum > 0 and current >= maximum:
                message = f"{hid} at {risk} capacity"
                if message in seen:
                    continue
                seen.add(message)
                items.append(
                    DebtItem(
                        severity="high" if risk == "R5" else "medium",
                        category="capacity",
                        message=message,
                        recommendation=f"reduce {hid}'s open {risk} load or add another authorized human",
                        risk=risk,
                    )
                )
    return items


def weak_evidence_items(workflows: list[tuple[Any, dict[str, Any]]]) -> list[DebtItem]:
    items: list[DebtItem] = []
    for artifact, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        for raw in artifact.lists.get("expected_decisions", []):
            decision = hgl.parse_decision(raw)
            risk = str(decision["risk"])
            if hgl.risk_number(risk) < 3:
                continue
            evidence = dict(decision["attrs"]).get("evidence", "normal")
            if evidence not in {"weak", "none_or_unknown"}:
                continue
            title = str(decision["title"])
            items.append(
                DebtItem(
                    severity="medium",
                    category="weak_evidence",
                    message=f"{workflow_id} {risk} decision has {evidence} evidence: {title}",
                    recommendation="add stronger evidence or narrow the decision before approval",
                    workflow=workflow_id,
                    risk=risk,
                )
            )
    return items


def risk_gap_items(workflows: list[tuple[Any, dict[str, Any]]]) -> list[DebtItem]:
    items: list[DebtItem] = []
    for _, data in workflows:
        workflow_id = str(data.get("workflow", ""))
        risk = str(data.get("risk_sources", {}).get("max_declared_risk", "R0"))
        for gap in data.get("risk_coverage_gaps", []):
            items.append(
                DebtItem(
                    severity="high" if hgl.risk_number(risk) >= 4 else "medium",
                    category="risk_coverage_gap",
                    message=str(gap),
                    recommendation="add an explicit expected human decision or reduce the declared risk",
                    workflow=workflow_id,
                    risk=risk,
                )
            )
    return items


def concentration_items(humans: list[hgl.Human]) -> list[DebtItem]:
    items: list[DebtItem] = []
    for human in sorted(humans, key=hgl.human_id):
        roles = sorted(set(human.roles))
        if len(roles) < 4:
            continue
        hid = hgl.human_id(human)
        items.append(
            DebtItem(
                severity="medium",
                category="concentration_risk",
                message=f"{hid} covers {len(roles)} governance roles",
                recommendation=f"split backup coverage for {hid}'s highest-risk roles",
                risk=human.authority_max_risk,
            )
        )
    return items


def r5_dual_human_item(workflows: list[tuple[Any, dict[str, Any]]], humans: list[hgl.Human]) -> list[DebtItem]:
    if hgl.risk_number(max_active_risk(workflows)) < 5:
        return []
    qualified = [
        human
        for human in humans
        if hgl.human_can_cover_risk(human, "R5")
        and human.may_approve_policy_changes
        and not hgl.human_at_risk_capacity(human, "R5")
    ]
    if len(qualified) >= 2:
        return []
    return [
        DebtItem(
            severity="high",
            category="r5_dual_human_coverage",
            message=f"R5 policy/governance changes have {len(qualified)} qualified human(s); two are required",
            recommendation="add a second active R5-authorized policy approver or keep R5 workflows simulation-only",
            risk="R5",
        )
    ]


def policy_candidate_item(root: pathlib.Path, args: argparse.Namespace) -> list[DebtItem]:
    count = policy_candidate_count(root, args)
    if count <= 0:
        return []
    decision_word = "decision is" if count == 1 else "decisions are"
    return [
        DebtItem(
            severity="low",
            category="policy_candidate",
            message=f"{count} low-risk repeated {decision_word} policy candidates",
            recommendation="review low-risk simulation policy candidates to reduce future HGL",
        )
    ]


def sort_items(items: list[DebtItem]) -> list[DebtItem]:
    return sorted(
        items,
        key=lambda item: (
            SEVERITY_ORDER.get(item.severity, 99),
            item.category,
            -hgl.risk_number(item.risk) if item.risk else 0,
            item.message,
        ),
    )


def debt_level(items: list[DebtItem]) -> str:
    if any(item.severity == "high" for item in items):
        return "high"
    if any(item.severity == "medium" for item in items):
        return "medium"
    if items:
        return "low"
    return "none"


def build_debt(root: pathlib.Path, args: argparse.Namespace) -> dict[str, Any]:
    root = root.resolve()
    workflows = workflow_rows(root, args)
    humans = active_humans(root, args)
    items = sort_items(
        missing_skill_items(workflows)
        + bottleneck_items(workflows)
        + capacity_items(workflows, humans)
        + weak_evidence_items(workflows)
        + risk_gap_items(workflows)
        + concentration_items(humans)
        + r5_dual_human_item(workflows, humans)
        + policy_candidate_item(root, args)
    )
    highest_leverage_fix = (
        items[0].recommendation
        if items
        else "No active Human Governance Debt detected for current workflows."
    )
    return {
        "level": debt_level(items),
        "item_count": len(items),
        "highest_leverage_fix": highest_leverage_fix,
        "items": [item.as_dict() for item in items],
    }


def print_text(data: dict[str, Any]) -> None:
    print(f"Human Governance Debt: {data['level']}")
    for item in data["items"]:
        print(f"- {item['message']}")
    if not data["items"]:
        print("- (none)")
    print(f"Highest leverage fix: {data['highest_leverage_fix']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--workflows-proposed-dir", required=True)
    parser.add_argument("--workflows-active-dir", required=True)
    parser.add_argument("--workflows-closed-dir", required=True)
    parser.add_argument("--humans-active-dir", required=True)
    parser.add_argument("--tickets-open-dir", required=True)
    parser.add_argument("--tickets-closed-dir", required=True)
    parser.add_argument("--decisions-decided-dir", required=True)
    parser.add_argument("--outcomes-recorded-dir", required=True)
    args = parser.parse_args()
    data = build_debt(pathlib.Path(args.root), args)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print_text(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
