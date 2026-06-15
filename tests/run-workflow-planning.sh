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
assert data["risk_sources"] == {
    "workflow_risk_ceiling": "R4",
    "max_work_unit_risk": "R4",
    "max_expected_decision_risk": "R4",
    "max_declared_risk": "R4",
}
assert data["risk_coverage_gaps"] == []
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
assert data["ai_can_proceed"] == ["research"]
assert "draft" in data["ai_must_not_proceed"]
assert "keep the workflow in research or simulation" in " ".join(data["recommended_next_actions"])
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
assert "full_autonomy" not in data["autonomy_ceiling"]
assert "high_autonomy" not in data["autonomy_ceiling"]
PY

printf 'workflow-planning: ok\n'
