#!/usr/bin/env python3
"""Read-only HGL calibration suggestions from recorded outcomes."""

from __future__ import annotations

import argparse
import json
from pathlib import Path, PurePosixPath
from typing import Any

from artifacts import frontmatter_dict, md_files, risk_number


def str_field(outcome: dict[str, Any], key: str) -> str:
    return str(outcome.get(key, "") or "")


def int_field(outcome: dict[str, Any], key: str) -> int | None:
    value = str_field(outcome, key)
    if not value:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def bool_true(outcome: dict[str, Any], key: str) -> bool:
    return str_field(outcome, key).lower() == "true"


def linked_evidence(outcome: dict[str, Any]) -> list[str]:
    raw = outcome.get("linked_evidence", [])
    if isinstance(raw, list):
        return [str(item) for item in raw if str(item)]
    return []


def decision_class(outcome: dict[str, Any]) -> str:
    decision = str_field(outcome, "decision")
    ticket = str_field(outcome, "ticket")
    workflow = str_field(outcome, "workflow")
    if decision:
        return f"decision:{decision}"
    if ticket:
        return f"ticket:{ticket}"
    if workflow:
        return f"workflow:{workflow}"
    return "general"


def evidence_template(path: str) -> str:
    name = PurePosixPath(path).name
    return name or path or "unspecified"


def outcome_row(path: Path, root: Path, outcome: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": str_field(outcome, "id") or path.stem,
        "title": str_field(outcome, "title"),
        "workflow": str_field(outcome, "workflow"),
        "ticket": str_field(outcome, "ticket"),
        "decision": str_field(outcome, "decision"),
        "decision_class": decision_class(outcome),
        "metric_name": str_field(outcome, "metric_name"),
        "metric_delta": str_field(outcome, "metric_delta"),
        "risk_predicted": str_field(outcome, "risk_predicted"),
        "risk_actual": str_field(outcome, "risk_actual"),
        "hgl_predicted": int_field(outcome, "hgl_predicted"),
        "hgl_actual": int_field(outcome, "hgl_actual"),
        "human_decisions_predicted": int_field(outcome, "human_decisions_predicted"),
        "human_decisions_actual": int_field(outcome, "human_decisions_actual"),
        "review_outcome": str_field(outcome, "review_outcome"),
        "rollback_used": bool_true(outcome, "rollback_used"),
        "policy_candidate": bool_true(outcome, "policy_candidate"),
        "linked_evidence": linked_evidence(outcome),
        "file": str(path.relative_to(root)),
    }


def hgl_delta(row: dict[str, Any]) -> int | None:
    predicted = row.get("hgl_predicted")
    actual = row.get("hgl_actual")
    if not isinstance(predicted, int) or not isinstance(actual, int):
        return None
    return predicted - actual


def risk_delta(row: dict[str, Any]) -> int | None:
    predicted = risk_number(str(row.get("risk_predicted", "")))
    actual = risk_number(str(row.get("risk_actual", "")))
    if predicted < 0 or actual < 0:
        return None
    return predicted - actual


def risk_direction(delta: int) -> str:
    if delta > 0:
        return "overestimated"
    if delta < 0:
        return "underestimated"
    return "matched"


def compact_row(row: dict[str, Any], *, include_evidence: bool = False) -> dict[str, Any]:
    data: dict[str, Any] = {
        "id": row["id"],
        "title": row["title"],
        "workflow": row["workflow"],
        "ticket": row["ticket"],
        "decision": row["decision"],
        "decision_class": row["decision_class"],
        "file": row["file"],
    }
    if row.get("metric_name"):
        data["metric_name"] = row["metric_name"]
    if row.get("metric_delta"):
        data["metric_delta"] = row["metric_delta"]
    if include_evidence:
        data["linked_evidence"] = row["linked_evidence"]
    return data


def build_hgl_item(row: dict[str, Any], delta: int) -> dict[str, Any]:
    data = compact_row(row, include_evidence=True)
    data.update(
        {
            "hgl_predicted": row["hgl_predicted"],
            "hgl_actual": row["hgl_actual"],
            "hgl_delta": delta,
        }
    )
    return data


def build_risk_item(row: dict[str, Any], delta: int) -> dict[str, Any]:
    data = compact_row(row)
    data.update(
        {
            "risk_predicted": row["risk_predicted"],
            "risk_actual": row["risk_actual"],
            "risk_delta": delta,
            "direction": risk_direction(delta),
        }
    )
    return data


def sorted_by_delta(items: list[dict[str, Any]], key: str) -> list[dict[str, Any]]:
    return sorted(items, key=lambda item: (-abs(int(item.get(key, 0))), str(item.get("id", ""))))


def policy_candidate_classes(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        if not row["policy_candidate"]:
            continue
        if row["review_outcome"] != "passed" or row["rollback_used"]:
            continue
        grouped.setdefault(str(row["decision_class"]), []).append(row)

    classes: list[dict[str, Any]] = []
    for label, items in grouped.items():
        hgl_reduction = sum(max(0, hgl_delta(item) or 0) for item in items)
        classes.append(
            {
                "decision_class": label,
                "successful_outcome_count": len(items),
                "total_hgl_reduction": hgl_reduction,
                "outcomes": [compact_row(item) for item in sorted(items, key=lambda row: row["id"])],
                "recommendation": "review for simulation-only policy or HGL calibration; human approval required",
            }
        )
    return sorted(classes, key=lambda item: (-item["successful_outcome_count"], item["decision_class"]))


def evidence_patterns(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        delta = hgl_delta(row)
        if delta is None or delta <= 0:
            continue
        if row["review_outcome"] != "passed" or row["rollback_used"]:
            continue
        references = row["linked_evidence"]
        if not references and row.get("metric_name"):
            references = [f"metric:{row['metric_name']}"]
        if not references:
            references = ["unspecified"]
        for reference in references:
            grouped.setdefault(evidence_template(reference), []).append(row)

    patterns: list[dict[str, Any]] = []
    for label, items in grouped.items():
        total_reduction = sum(max(0, hgl_delta(item) or 0) for item in items)
        patterns.append(
            {
                "evidence_template": label,
                "outcome_count": len(items),
                "total_hgl_reduction": total_reduction,
                "outcomes": [
                    build_hgl_item(item, hgl_delta(item) or 0)
                    for item in sorted(items, key=lambda row: row["id"])
                ],
                "recommendation": "consider making this evidence pattern reusable before changing HGL weights",
            }
        )
    return sorted(patterns, key=lambda item: (-item["total_hgl_reduction"], item["evidence_template"]))


def recommendations(
    overestimated: list[dict[str, Any]],
    underestimated: list[dict[str, Any]],
    risk_mismatches: list[dict[str, Any]],
    policy_classes: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
) -> list[str]:
    items: list[str] = []
    if overestimated:
        top = overestimated[0]
        items.append(
            f"Review {top['decision_class']} for possible lower HGL after human approval "
            f"(largest overestimate: {top['id']} by {top['hgl_delta']})."
        )
    if underestimated:
        top = underestimated[0]
        items.append(
            f"Review {top['decision_class']} for stricter planning or higher HGL "
            f"(largest underestimate: {top['id']} by {abs(int(top['hgl_delta']))})."
        )
    if risk_mismatches:
        top = risk_mismatches[0]
        items.append(
            f"Review risk estimate for {top['decision_class']} "
            f"({top['id']} was {top['direction']}: {top['risk_predicted']} -> {top['risk_actual']})."
        )
    if policy_classes:
        top = policy_classes[0]
        items.append(
            f"Review {top['decision_class']} as a simulation-only policy candidate; "
            "human approval is still required."
        )
    if evidence:
        top = evidence[0]
        items.append(
            f"Promote reusable evidence pattern '{top['evidence_template']}' before changing HGL weights."
        )
    if not items:
        items.append("No calibration changes suggested yet; keep collecting reviewed outcomes.")
    return items


def build_report(root: Path, outcomes_recorded_dir: str) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for path in md_files(root, outcomes_recorded_dir):
        outcome = frontmatter_dict(path)
        rows.append(outcome_row(path, root, outcome))

    overestimated: list[dict[str, Any]] = []
    underestimated: list[dict[str, Any]] = []
    risk_mismatches: list[dict[str, Any]] = []
    impact_count = 0
    for row in rows:
        if hgl_delta(row) is not None or risk_delta(row) is not None:
            impact_count += 1
        delta = hgl_delta(row)
        if delta is not None and delta > 0:
            overestimated.append(build_hgl_item(row, delta))
        elif delta is not None and delta < 0:
            underestimated.append(build_hgl_item(row, delta))
        r_delta = risk_delta(row)
        if r_delta is not None and r_delta != 0:
            risk_mismatches.append(build_risk_item(row, r_delta))

    overestimated = sorted_by_delta(overestimated, "hgl_delta")
    underestimated = sorted_by_delta(underestimated, "hgl_delta")
    risk_mismatches = sorted_by_delta(risk_mismatches, "risk_delta")
    policy_classes = policy_candidate_classes(rows)
    evidence = evidence_patterns(rows)
    return {
        "mode": "read_only",
        "weight_changes_applied": False,
        "policy_changes_applied": False,
        "outcomes_considered": len(rows),
        "impact_outcomes_considered": impact_count,
        "overestimated_hgl": overestimated,
        "underestimated_hgl": underestimated,
        "risk_mismatches": risk_mismatches,
        "policy_candidate_classes": policy_classes,
        "evidence_patterns": evidence,
        "recommendations": recommendations(
            overestimated, underestimated, risk_mismatches, policy_classes, evidence
        ),
    }


def bullet_item(item: dict[str, Any], *, hgl: bool = False, risk: bool = False) -> str:
    base = f"- {item['id']} {item['decision_class']}"
    if hgl:
        base += (
            f": predicted {item['hgl_predicted']} actual {item['hgl_actual']} "
            f"(delta {item['hgl_delta']})"
        )
    if risk:
        base += f": {item['risk_predicted']} -> {item['risk_actual']} ({item['direction']})"
    if item.get("metric_name"):
        base += f"; metric {item['metric_name']} delta {item.get('metric_delta', '')}"
    return base


def text_report(data: dict[str, Any]) -> str:
    lines = [
        "HGL calibration report",
        "Mode: read-only; no weights or policies were changed.",
        f"Outcomes considered: {data['outcomes_considered']}",
        f"Impact outcomes considered: {data['impact_outcomes_considered']}",
        "",
        "Overestimated HGL:",
    ]
    if data["overestimated_hgl"]:
        lines.extend(bullet_item(item, hgl=True) for item in data["overestimated_hgl"])
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("Underestimated HGL:")
    if data["underestimated_hgl"]:
        lines.extend(bullet_item(item, hgl=True) for item in data["underestimated_hgl"])
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("Risk estimate mismatches:")
    if data["risk_mismatches"]:
        lines.extend(bullet_item(item, risk=True) for item in data["risk_mismatches"])
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("Policy candidate classes:")
    if data["policy_candidate_classes"]:
        for item in data["policy_candidate_classes"]:
            lines.append(
                f"- {item['decision_class']}: {item['successful_outcome_count']} successful outcome(s); "
                f"HGL reduction {item['total_hgl_reduction']}"
            )
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("Evidence patterns that reduced HGL:")
    if data["evidence_patterns"]:
        for item in data["evidence_patterns"]:
            lines.append(
                f"- {item['evidence_template']}: {item['outcome_count']} outcome(s); "
                f"HGL reduction {item['total_hgl_reduction']}"
            )
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("Recommendations:")
    lines.extend(f"- {item}" for item in data["recommendations"])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--outcomes-recorded-dir", required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    data = build_report(Path(args.root), args.outcomes_recorded_dir)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(text_report(data), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
