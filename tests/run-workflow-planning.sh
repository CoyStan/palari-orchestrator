#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'workflow-planning: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-workflow-planning.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md

git init -b main >/dev/null
git config user.email "plan@example.invalid"
git config user.name "Plan Test"
git add .
git commit -m "planning baseline" >/dev/null

./bin/palari human create HUMAN-ALICE Alice \
	--skill product_strategy:L5 \
	--skill technical_governance:L4 \
	--role product_governor \
	--capacity-hgl 60 \
	--authority-max-risk R5 \
	--may-approve-policy-changes >/dev/null
./bin/palari human adopt HUMAN-ALICE --by founder >/dev/null

./bin/palari human create HUMAN-BOB Bob \
	--skill analytics:L3 \
	--role analytics_reviewer \
	--capacity-hgl 20 \
	--authority-max-risk R3 >/dev/null
./bin/palari human adopt HUMAN-BOB --by founder >/dev/null

./bin/palari workflow create WF-0001 "Improve onboarding activation" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R4 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0001-improve-onboarding-activation.md")
text = path.read_text()
text = text.replace(
    "work_units:\n",
    "work_units:\n"
    "  - WU-0001|research|R1|Analyze onboarding dropoff\n"
    "  - WU-0002|rollout|R4|Production rollout decision\n",
)
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R3|choose|product_strategy:L4,analytics:L3|Choose experiment direction|novelty=medium|ambiguity=medium\n"
    "  - R4|approve|technical_governance:L4|Approve production rollout|context=high\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0001 --by founder >/dev/null

git_state_before="$(git status --porcelain | sort)"
./bin/palari workflow plan WF-0001 >"$TMP_ROOT/plan.out"
git_state_after="$(git status --porcelain | sort)"
[[ "$git_state_before" == "$git_state_after" ]] ||
	fail "workflow plan mutated repository state"

grep -Fq "Workflow: WF-0001 Improve onboarding activation" "$TMP_ROOT/plan.out" ||
	fail "workflow title missing"
grep -Fq "Goal: GOAL-0100" "$TMP_ROOT/plan.out" || fail "goal missing"
grep -Fq "Launch gate: yellow" "$TMP_ROOT/plan.out" || fail "yellow gate missing"
grep -Fq "Autonomy ceiling: human_led" "$TMP_ROOT/plan.out" || fail "human-led ceiling missing"
grep -Fq "AI can proceed:" "$TMP_ROOT/plan.out" || fail "AI can proceed section missing"
grep -Fq -- "- staging" "$TMP_ROOT/plan.out" || fail "staging mode should remain available"
grep -Fq "AI must not proceed:" "$TMP_ROOT/plan.out" || fail "AI blocked section missing"
grep -Fq -- "- production_write_without_human" "$TMP_ROOT/plan.out" ||
	fail "production write block missing"
grep -Fq "Human Governance Load: 15" "$TMP_ROOT/plan.out" || fail "HGL total missing"
grep -Fq "R3 decisions: 1" "$TMP_ROOT/plan.out" || fail "R3 count missing"
grep -Fq "R4 decisions: 1" "$TMP_ROOT/plan.out" || fail "R4 count missing"
grep -Fq "Human decision map:" "$TMP_ROOT/plan.out" ||
	fail "human decision map section missing"
grep -Fq -- "- R4 approve: Approve production rollout" "$TMP_ROOT/plan.out" ||
	fail "R4 decision map row missing"
grep -Fq "status: covered by one" "$TMP_ROOT/plan.out" ||
	fail "decision map coverage status missing"
grep -Fq "HGL: 12" "$TMP_ROOT/plan.out" ||
	fail "decision map HGL score missing"
grep -Fq "eligible: HUMAN-ALICE" "$TMP_ROOT/plan.out" ||
	fail "decision map eligible human missing"
grep -Fq "product_strategy L4: covered by HUMAN-ALICE" "$TMP_ROOT/plan.out" ||
	fail "product strategy coverage missing"
grep -Fq "analytics L3: covered by HUMAN-BOB" "$TMP_ROOT/plan.out" ||
	fail "analytics coverage missing"
grep -Fq "add backup coverage for bottleneck role product_governor" "$TMP_ROOT/plan.out" ||
	fail "bottleneck recommendation missing"
grep -Fq "workflow planning is read-only" "$TMP_ROOT/plan.out" ||
	fail "read-only note missing"

./bin/palari workflow plan WF-0001 --json >"$TMP_ROOT/plan.json"
python3 - "$TMP_ROOT/plan.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["workflow"] == "WF-0001"
assert data["goal"] == "GOAL-0100"
assert data["launch_gate"] == "yellow"
assert data["autonomy_ceiling"] == "human_led"
assert "staging" in data["ai_can_proceed"]
assert "production_write_without_human" in data["ai_must_not_proceed"]
assert data["human_governance_load"] == 15
assert data["expected_decisions"]["R3"] == 1
assert data["expected_decisions"]["R4"] == 1
assert [item["risk"] for item in data["human_decision_map"]] == ["R4", "R3"]
assert data["human_decision_map"][0] == {
    "risk": "R4",
    "kind": "approve",
    "title": "Approve production rollout",
    "hgl_score": 12,
    "required_skills": {"technical_governance": "L4"},
    "eligible_humans": ["HUMAN-ALICE"],
    "coverage_status": "covered_by_one",
    "why_human_needed": [
        "R4 company-impact decision",
        "required skill: technical_governance L4",
    ],
}
assert data["risk_sources"] == {
    "workflow_risk_ceiling": "R4",
    "max_work_unit_risk": "R4",
    "max_expected_decision_risk": "R4",
    "max_declared_risk": "R4",
}
assert data["risk_coverage_gaps"] == []
assert data["capacity"] == {
    "weekly_hgl_budget": 80,
    "current_weekly_hgl": 0,
    "available_weekly_hgl": 80,
    "risk_capacity_failures": [],
}
assert data["required_skills"]["product_strategy"]["covered_by"] == ["HUMAN-ALICE"]
assert data["required_skills"]["analytics"]["covered_by"] == ["HUMAN-BOB"]
assert any("product_governor" in item for item in data["recommended_next_actions"])
PY

./bin/palari workflow create WF-0002 "Privacy rollout" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R5 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0002-privacy-rollout.md")
text = path.read_text()
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R5|approve|privacy:L5|Approve privacy policy boundary|novelty=high|ambiguity=high|irreversibility=high\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0002 --by founder >/dev/null
./bin/palari workflow plan WF-0002 --json >"$TMP_ROOT/red.json"
python3 - "$TMP_ROOT/red.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["launch_gate"] == "red"
assert data["autonomy_ceiling"] == "simulation_only"
assert data["missing_skills"] == ["privacy:L5"]
assert data["human_decision_map"][0]["risk"] == "R5"
assert data["human_decision_map"][0]["kind"] == "approve"
assert data["human_decision_map"][0]["required_skills"] == {"privacy": "L5"}
assert data["human_decision_map"][0]["eligible_humans"] == []
assert data["human_decision_map"][0]["coverage_status"] == "missing_skill"
assert "R5 governance decision" in data["human_decision_map"][0]["why_human_needed"]
assert "no policy acceptance allowed" in data["human_decision_map"][0]["why_human_needed"]
assert data["ai_can_proceed"] == ["research"]
assert "draft" in data["ai_must_not_proceed"]
assert "keep the workflow in research or simulation" in " ".join(data["recommended_next_actions"])
PY

./bin/palari decide inbox --json >"$TMP_ROOT/inbox.json"
python3 - "$TMP_ROOT/inbox.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["read_only"] is True
assert data["created_or_recorded_decisions"] is False
assert data["counts_by_risk"]["R5"] == 1, data
assert data["counts_by_risk"]["R4"] == 1, data
assert data["counts_by_risk"]["R3"] == 1, data
assert data["items"][0]["risk"] == "R5", data["items"]
assert data["items"][0]["coverage_status"] == "missing_skill", data["items"][0]
assert data["items"][1]["risk"] == "R4", data["items"]
assert data["items"][2]["risk"] == "R3", data["items"]
assert data["recommended_order"][0]["title"] == "Approve privacy policy boundary", data["recommended_order"]
PY

./bin/palari workflow create WF-0003 "R5 ceiling without decisions" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R5 >/dev/null
./bin/palari workflow adopt WF-0003 --by founder >/dev/null
./bin/palari workflow plan WF-0003 --json >"$TMP_ROOT/r5-ceiling.json"
python3 - "$TMP_ROOT/r5-ceiling.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["risk_sources"]["workflow_risk_ceiling"] == "R5", data["risk_sources"]
assert data["risk_sources"]["max_declared_risk"] == "R5", data["risk_sources"]
assert data["launch_gate"] == "red", data
assert data["autonomy_ceiling"] == "simulation_only", data
assert data["risk_coverage_gaps"] == [
    "workflow risk ceiling R5 has no expected decision at or above that risk"
], data["risk_coverage_gaps"]
assert data["human_decision_map"] == []
assert "full_autonomy" not in data["autonomy_ceiling"]
assert "high_autonomy" not in data["autonomy_ceiling"]
PY

./bin/palari workflow create WF-0004 "R3 source without decision" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R3 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0004-r3-source-without-decision.md")
text = path.read_text()
text = text.replace(
    "work_units:\n",
    "work_units:\n"
    "  - WU-0001|analysis|R3|Analyze customer-impacting change\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0004 --by founder >/dev/null
./bin/palari workflow plan WF-0004 --json >"$TMP_ROOT/r3-no-decision.json"
python3 - "$TMP_ROOT/r3-no-decision.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["risk_sources"]["workflow_risk_ceiling"] == "R3", data["risk_sources"]
assert data["risk_sources"]["max_work_unit_risk"] == "R3", data["risk_sources"]
assert data["risk_sources"]["max_declared_risk"] == "R3", data["risk_sources"]
assert data["launch_gate"] == "yellow", data
assert data["autonomy_ceiling"] == "conditional_autonomy", data
assert data["risk_coverage_gaps"] == [
    "work unit WU-0001 R3 has no expected decision at or above that risk",
    "workflow risk ceiling R3 has no expected decision at or above that risk",
], data["risk_coverage_gaps"]
assert any("add expected human decision coverage" in item for item in data["recommended_next_actions"])
PY

./bin/palari workflow create WF-0005 "R3 source with exception" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R3 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0005-r3-source-with-exception.md")
text = path.read_text()
text = text.replace(
    "work_units:\n",
    "work_units:\n"
    "  - WU-0001|analysis|R3|Analyze customer-impacting change\n",
)
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "human_decision_exceptions:\n"
    "  - R3 analysis is exploratory and will route to a separate decision before production use.\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0005 --by founder >/dev/null
./bin/palari workflow plan WF-0005 --json >"$TMP_ROOT/r3-exception.json"
python3 - "$TMP_ROOT/r3-exception.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["risk_sources"]["max_declared_risk"] == "R3", data["risk_sources"]
assert data["launch_gate"] == "green", data
assert data["autonomy_ceiling"] == "conditional_autonomy", data
assert data["risk_coverage_gaps"] == [], data["risk_coverage_gaps"]
PY

printf 'workflow-planning: ok\n'
