#!/usr/bin/env python3
"""Compact company OS snapshot section for Palari."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
from types import SimpleNamespace
from typing import Any

import hgl
import governance_debt
import policy_candidates
from artifacts import md_files


def read_text(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def parse_config(root: pathlib.Path) -> dict[str, Any]:
    flat: dict[str, str] = {}
    lists: dict[str, list[str]] = {}
    current_list: str | None = None
    for raw in read_text(root / "palari.config.yaml").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw.startswith((" ", "\t")):
            line = raw.strip()
            if line.startswith("- ") and current_list:
                lists[current_list].append(strip_quotes(line[2:]))
            continue
        current_list = None
        match = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", raw.strip())
        if not match:
            continue
        key, value = match.group(1), re.sub(r"\s+#.*$", "", match.group(2)).strip()
        if value:
            flat[key] = strip_quotes(value)
        else:
            flat[key] = ""
            lists[key] = []
            current_list = key
    return {"flat": flat, "lists": lists}


def cfg(config: dict[str, Any], key: str, default: str) -> str:
    flat = config.get("flat", {})
    value = flat.get(key, "")
    return value if value else default


def empty_company_os() -> dict[str, Any]:
    return {
        "workflows": {"active": 0, "proposed": 0, "closed": 0, "items": []},
        "humans": {"active": 0, "proposed": 0, "revoked": 0, "coverage_gaps": []},
        "human_governance": {
            "open_hgl_estimate": 0,
            "r3_decisions_open": 0,
            "r4_decisions_open": 0,
            "r5_decisions_open": 0,
            "missing_skills": [],
            "bottlenecks": [],
            "capacity_warnings": [],
            "debt": {
                "level": "none",
                "item_count": 0,
                "highest_leverage_fix": "No active Human Governance Debt detected for current workflows.",
            },
        },
        "autonomy": {"green_workflows": 0, "yellow_workflows": 0, "red_workflows": 0},
        "policy": {
            "simulation_only": True,
            "candidates": 0,
            "active_policies": 0,
            "proposed_policies": 0,
        },
        "broker": {
            "real_side_effects_enabled": False,
            "mock_observations": 0,
            "tickets_with_broker_evidence": [],
        },
        "outcomes": {"open": 0, "recorded": 0, "invalidated": 0},
    }


def count_invalidated_outcomes(paths: list[pathlib.Path]) -> int:
    count = 0
    for path in paths:
        try:
            artifact = hgl.parse_frontmatter(path)
        except (OSError, ValueError):
            continue
        if artifact.fields.get("status") == "invalidated":
            count += 1
    return count


def policy_candidate_count(root: pathlib.Path, dirs: dict[str, str]) -> int:
    args = SimpleNamespace(
        tickets_open_dir=dirs["tickets_open"],
        tickets_closed_dir=dirs["tickets_closed"],
        decisions_decided_dir=dirs["decisions_decided"],
        outcomes_recorded_dir=dirs["outcomes_recorded"],
    )
    try:
        data = policy_candidates.build_candidates(root, args)
    except (OSError, ValueError):
        return 0
    return int(data.get("candidate_count", 0))


def broker_summary(root: pathlib.Path, evidence_dir: str) -> dict[str, Any]:
    base = root / evidence_dir
    tickets: set[str] = set()
    mock_observations = 0
    real_side_effects = False
    if not base.is_dir():
        return {
            "real_side_effects_enabled": False,
            "mock_observations": 0,
            "tickets_with_broker_evidence": [],
        }
    for path in sorted(base.glob("*/broker/*/summary.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        ticket = str(data.get("ticket") or path.relative_to(base).parts[0])
        tickets.add(ticket)
        mode = str(data.get("mode") or data.get("broker_mode") or "")
        if mode == "mock":
            mock_observations += 1
        if bool(data.get("side_effects_enabled")) or bool(data.get("real_side_effects_enabled")):
            real_side_effects = True
    return {
        "real_side_effects_enabled": real_side_effects,
        "mock_observations": mock_observations,
        "tickets_with_broker_evidence": sorted(tickets),
    }


def build_company_os(root: pathlib.Path, config: dict[str, Any] | None = None) -> dict[str, Any]:
    root = root.resolve()
    config = config or parse_config(root)
    dirs = {
        "workflows_proposed": cfg(config, "workflows_proposed_dir", "workflows/proposed"),
        "workflows_active": cfg(config, "workflows_active_dir", "workflows/active"),
        "workflows_closed": cfg(config, "workflows_closed_dir", "workflows/closed"),
        "humans_proposed": cfg(config, "humans_proposed_dir", "humans/proposed"),
        "humans_active": cfg(config, "humans_active_dir", "humans/active"),
        "humans_revoked": cfg(config, "humans_revoked_dir", "humans/revoked"),
        "policies_proposed": cfg(config, "policies_proposed_dir", "policies/proposed"),
        "policies_active": cfg(config, "policies_active_dir", "policies/active"),
        "policies_revoked": cfg(config, "policies_revoked_dir", "policies/revoked"),
        "outcomes_open": cfg(config, "outcomes_open_dir", "outcomes/open"),
        "outcomes_recorded": cfg(config, "outcomes_recorded_dir", "outcomes/recorded"),
        "decisions_decided": cfg(config, "decisions_decided_dir", "decisions/decided"),
        "tickets_open": cfg(config, "tickets_open_dir", "tickets/open"),
        "tickets_closed": cfg(config, "tickets_closed_dir", "tickets/closed"),
        "evidence": cfg(config, "evidence_dir", "reports/evidence"),
    }
    section = empty_company_os()
    workflow_files = {
        "proposed": md_files(root, dirs["workflows_proposed"]),
        "active": md_files(root, dirs["workflows_active"]),
        "closed": md_files(root, dirs["workflows_closed"]),
    }
    human_files = {
        "proposed": md_files(root, dirs["humans_proposed"]),
        "active": md_files(root, dirs["humans_active"]),
        "revoked": md_files(root, dirs["humans_revoked"]),
    }
    policy_files = {
        "proposed": md_files(root, dirs["policies_proposed"]),
        "active": md_files(root, dirs["policies_active"]),
        "revoked": md_files(root, dirs["policies_revoked"]),
    }
    outcome_files = {
        "open": md_files(root, dirs["outcomes_open"]),
        "recorded": md_files(root, dirs["outcomes_recorded"]),
    }
    section["workflows"]["proposed"] = len(workflow_files["proposed"])
    section["workflows"]["active"] = len(workflow_files["active"])
    section["workflows"]["closed"] = len(workflow_files["closed"])
    section["humans"]["proposed"] = len(human_files["proposed"])
    section["humans"]["active"] = len(human_files["active"])
    section["humans"]["revoked"] = len(human_files["revoked"])

    missing_skills: set[str] = set()
    bottlenecks: set[str] = set()
    capacity_warnings: set[str] = set()
    hgl_total = 0
    r3 = r4 = r5 = 0
    autonomy_counts = {"green": 0, "yellow": 0, "red": 0}
    items: list[dict[str, Any]] = []

    for path in workflow_files["active"]:
        try:
            artifact = hgl.parse_frontmatter(path)
            workflow_id = artifact.fields.get("id", path.stem)
            args = SimpleNamespace(
                workflow=workflow_id,
                workflows_proposed_dir=dirs["workflows_proposed"],
                workflows_active_dir=dirs["workflows_active"],
                workflows_closed_dir=dirs["workflows_closed"],
                humans_active_dir=dirs["humans_active"],
            )
            data = hgl.analyze(root, args)
        except (OSError, ValueError, SystemExit):
            continue
        hgl_total += int(data["human_governance_load"])
        counts = data["expected_decisions"]
        r3 += int(counts.get("R3", 0))
        r4 += int(counts.get("R4", 0))
        r5 += int(counts.get("R5", 0))
        missing_skills.update(data.get("missing_skills", []))
        bottlenecks.update(data.get("bottlenecks", []))
        capacity = data.get("capacity", {})
        for failure in capacity.get("risk_capacity_failures", []):
            capacity_warnings.add(str(failure))
        if int(data.get("human_governance_load", 0)) > int(capacity.get("available_weekly_hgl", 0)):
            capacity_warnings.add(f"{workflow_id} exceeds available weekly HGL")
        gate = str(data["launch_gate"])
        if gate in autonomy_counts:
            autonomy_counts[gate] += 1
        items.append(
            {
                "id": workflow_id,
                "title": data.get("title", ""),
                "status": "active",
                "goal": artifact.fields.get("goal", ""),
                "risk_ceiling": artifact.fields.get("risk_ceiling", ""),
                "human_governance_load": data["human_governance_load"],
                "launch_gate": gate,
                "autonomy_ceiling": data["autonomy_ceiling"],
                "missing_skills": data.get("missing_skills", []),
                "bottlenecks": data.get("bottlenecks", []),
                "risk_sources": data.get("risk_sources", {}),
                "capacity": data.get("capacity", {}),
                "path": str(path.relative_to(root)),
            }
        )

    section["workflows"]["items"] = sorted(items, key=lambda item: item["id"])
    section["humans"]["coverage_gaps"] = sorted(missing_skills)
    debt_args = SimpleNamespace(
        workflows_proposed_dir=dirs["workflows_proposed"],
        workflows_active_dir=dirs["workflows_active"],
        workflows_closed_dir=dirs["workflows_closed"],
        humans_active_dir=dirs["humans_active"],
        tickets_open_dir=dirs["tickets_open"],
        tickets_closed_dir=dirs["tickets_closed"],
        decisions_decided_dir=dirs["decisions_decided"],
        outcomes_recorded_dir=dirs["outcomes_recorded"],
    )
    debt = governance_debt.build_debt(root, debt_args)
    section["human_governance"] = {
        "open_hgl_estimate": hgl_total,
        "r3_decisions_open": r3,
        "r4_decisions_open": r4,
        "r5_decisions_open": r5,
        "missing_skills": sorted(missing_skills),
        "bottlenecks": sorted(bottlenecks),
        "capacity_warnings": sorted(capacity_warnings),
        "debt": {
            "level": debt["level"],
            "item_count": debt["item_count"],
            "highest_leverage_fix": debt["highest_leverage_fix"],
        },
    }
    section["autonomy"] = {
        "green_workflows": autonomy_counts["green"],
        "yellow_workflows": autonomy_counts["yellow"],
        "red_workflows": autonomy_counts["red"],
    }
    section["policy"] = {
        "simulation_only": True,
        "candidates": policy_candidate_count(root, dirs),
        "active_policies": len(policy_files["active"]),
        "proposed_policies": len(policy_files["proposed"]),
    }
    section["broker"] = broker_summary(root, dirs["evidence"])
    section["outcomes"] = {
        "open": len(outcome_files["open"]),
        "recorded": len(outcome_files["recorded"]),
        "invalidated": count_invalidated_outcomes(outcome_files["open"] + outcome_files["recorded"]),
    }
    return section


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    args = parser.parse_args()
    print(json.dumps(build_company_os(pathlib.Path(args.root)), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
