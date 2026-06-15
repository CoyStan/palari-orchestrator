#!/usr/bin/env python3
"""Suggest conservative policy candidates from decided decisions."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

from artifacts import find_frontmatter_file, frontmatter_dict as parse_frontmatter, md_files


LOW_RISKS = {"R0", "R1", "R2"}
HGL_WEIGHTS = {"R0": 1, "R1": 1, "R2": 3}


def find_by_id(root: Path, dirs: list[str], artifact_id: str) -> tuple[Path, dict[str, Any]] | None:
    return find_frontmatter_file(root, dirs, artifact_id, required=False)


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


def bool_true(value: Any) -> bool:
    return str(value).lower() == "true"


def ratio(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return round(numerator / denominator, 4)


def indexed_outcomes(root: Path, outcomes_recorded_dir: str) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in md_files(root, outcomes_recorded_dir):
        outcome = parse_frontmatter(path)
        item = {
            "id": str(outcome.get("id", path.stem)),
            "title": str(outcome.get("title", "")),
            "status": str(outcome.get("status", "")),
            "review_outcome": str(outcome.get("review_outcome", "")),
            "rollback_used": str(outcome.get("rollback_used", "")),
            "policy_candidate": str(outcome.get("policy_candidate", "")),
            "metric_name": str(outcome.get("metric_name", "")),
            "metric_delta": str(outcome.get("metric_delta", "")),
            "risk_actual": str(outcome.get("risk_actual", "")),
            "hgl_actual": str(outcome.get("hgl_actual", "")),
            "linked_evidence": outcome.get("linked_evidence", []),
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


def outcome_failed(outcome: dict[str, Any]) -> bool:
    return (
        outcome.get("status") == "invalidated"
        or outcome.get("review_outcome") in {"failed", "overridden"}
        or bool_true(outcome.get("rollback_used", ""))
    )


def outcome_successful(outcome: dict[str, Any]) -> bool:
    return outcome.get("review_outcome") == "passed" and not outcome_failed(outcome)


def outcome_evidence_count(outcomes: list[dict[str, Any]]) -> int:
    count = 0
    for outcome in outcomes:
        raw = outcome.get("linked_evidence", [])
        if isinstance(raw, list):
            count += len([item for item in raw if str(item)])
    return count


def confidence_label(score: int) -> str:
    if score >= 80:
        return "high"
    if score >= 60:
        return "medium"
    return "low"


def confidence_score(
    approval_count: int,
    override_count: int,
    successful_outcomes: int,
    failed_outcomes: int,
    evidence_count: int,
) -> int:
    score = 60 + min(20, max(0, approval_count - 3) * 5)
    if successful_outcomes:
        score += 20
    if evidence_count:
        score += 10
    score -= min(40, override_count * 20)
    score -= min(40, failed_outcomes * 20)
    return max(0, min(100, score))


def evidence_signal(evidence_count: int, outcome_count: int) -> str:
    if outcome_count == 0:
        return "no_recorded_outcomes"
    if evidence_count > 0:
        return "linked_outcome_evidence"
    return "no_linked_outcome_evidence"


def build_candidates(root: Path, args: argparse.Namespace) -> dict[str, Any]:
    outcomes = indexed_outcomes(root, args.outcomes_recorded_dir)
    groups: dict[tuple[str, str, str, str, str], list[dict[str, Any]]] = defaultdict(list)
    override_groups: dict[tuple[str, str, str, str, str], list[dict[str, Any]]] = defaultdict(list)
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
        if not recommended:
            skipped_not_recommended += 1
            continue
        kind = str(ticket.get("stream", "") or "general")
        recommended_text = option_text(decision, recommended)
        key = (risk, kind, recommended, recommended, recommended_text)
        item = {
            "decision": decision.get("id", decision_path.stem),
            "decision_title": decision.get("title", ""),
            "decision_file": str(decision_path.relative_to(root)),
            "ticket": ticket_id,
            "ticket_file": str(ticket_path.relative_to(root)),
            "recommended_option": recommended,
            "chosen_option": chosen,
            "chosen_text": option_text(decision, chosen),
            "linked_outcomes": outcomes.get(ticket_id, []) + outcomes.get(str(decision.get("id", "")), []),
        }
        if recommended != chosen:
            skipped_not_recommended += 1
            override_groups[key].append(item)
            continue
        groups[key].append(item)

    candidates: list[dict[str, Any]] = []
    for (risk, kind, recommended, chosen, chosen_text), items in sorted(groups.items()):
        count = len(items)
        if count < 3:
            continue
        policy_kind = slug_token(kind)
        policy_id = f"POL-{policy_kind}-{risk}-AUTO"
        title = candidate_title(kind, risk)
        hgl_reduction = count * HGL_WEIGHTS.get(risk, 1)
        overrides = override_groups.get((risk, kind, recommended, chosen, chosen_text), [])
        total_similar = count + len(overrides)
        linked_outcomes: list[dict[str, Any]] = []
        seen_outcomes: set[str] = set()
        successful_outcomes = 0
        failed_outcomes = 0
        rollback_outcomes = 0
        invalidated_outcomes = 0
        for item in items + overrides:
            for outcome in item["linked_outcomes"]:
                if outcome["id"] in seen_outcomes:
                    continue
                seen_outcomes.add(outcome["id"])
                linked_outcomes.append(outcome)
                if outcome_successful(outcome):
                    successful_outcomes += 1
                if outcome_failed(outcome):
                    failed_outcomes += 1
                if bool_true(outcome.get("rollback_used", "")):
                    rollback_outcomes += 1
                if outcome.get("status") == "invalidated":
                    invalidated_outcomes += 1
        evidence_count = outcome_evidence_count(linked_outcomes)
        score = confidence_score(
            count,
            len(overrides),
            successful_outcomes,
            failed_outcomes,
            evidence_count,
        )
        outcome_count = len(linked_outcomes)
        reason = (
            f"{count} {kind} approvals; {len(overrides)} overrides; "
            f"{successful_outcomes}/{outcome_count} successful outcomes; "
            f"{failed_outcomes} rollback/failure outcomes; "
            f"evidence: {evidence_signal(evidence_count, outcome_count)}"
        )
        candidates.append(
            {
                "id": policy_id,
                "title": title,
                "risk": risk,
                "kind": kind,
                "decision_count": count,
                "similar_decision_count": total_similar,
                "approval_count": count,
                "override_count": len(overrides),
                "human_approval_rate": ratio(count, total_similar),
                "human_override_rate": ratio(len(overrides), total_similar),
                "recommended_option": recommended,
                "chosen_option": chosen,
                "chosen_text": chosen_text,
                "suggested_mode": "simulation",
                "expected_hgl_reduction": hgl_reduction,
                "linked_outcome_count": len(linked_outcomes),
                "successful_outcome_count": successful_outcomes,
                "failed_or_rollback_outcome_count": failed_outcomes,
                "rollback_outcome_count": rollback_outcomes,
                "invalidated_outcome_count": invalidated_outcomes,
                "outcome_success_rate": ratio(successful_outcomes, outcome_count),
                "rollback_failure_rate": ratio(failed_outcomes, outcome_count),
                "linked_evidence_count": evidence_count,
                "evidence_signal": evidence_signal(evidence_count, outcome_count),
                "confidence": confidence_label(score),
                "confidence_score": score,
                "reason": reason,
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
                "override_examples": overrides[:5],
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
                f"Approval rate: {candidate['human_approval_rate']:.0%} ({candidate['approval_count']}/{candidate['similar_decision_count']})",
                f"Override rate: {candidate['human_override_rate']:.0%} ({candidate['override_count']}/{candidate['similar_decision_count']})",
                f"Linked outcomes: {candidate['linked_outcome_count']} recorded",
                f"Successful outcomes: {candidate['successful_outcome_count']} recorded",
                f"Outcome success rate: {candidate['outcome_success_rate']:.0%} ({candidate['successful_outcome_count']}/{candidate['linked_outcome_count']})",
                f"Rollback/failure rate: {candidate['rollback_failure_rate']:.0%} ({candidate['failed_or_rollback_outcome_count']}/{candidate['linked_outcome_count']})",
                f"Evidence signal: {candidate['evidence_signal']}",
                f"Confidence: {candidate['confidence']} ({candidate['confidence_score']})",
                f"Reason: {candidate['reason']}",
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
