#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'company-os-snapshot: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-company-os-snapshot.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md decisions/open/*.md decisions/decided/*.md memory/decisions/*.md outcomes/open/*.md outcomes/recorded/*.md policies/proposed/*.md policies/active/*.md policies/revoked/*.md

git init -b main >/dev/null
git config user.email "snapshot@example.invalid"
git config user.name "Snapshot Test"
git add .
git commit -m "snapshot baseline" >/dev/null

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
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R3|choose|product_strategy:L4,analytics:L3|Choose experiment direction|novelty=medium|ambiguity=medium\n"
    "  - R4|approve|technical_governance:L4|Approve production rollout|context=high\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0001 --by founder >/dev/null

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

./bin/palari ticket create BRK-0200 "Snapshot broker observation" \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--allowed reports/evidence/BRK-0200/** \
	--verify "test -f README.md" >/dev/null
./bin/palari broker run BRK-0200 --mock -- printf "snapshot broker" >/dev/null

./bin/palari snapshot --json >"$TMP_ROOT/fast.json"
PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json >"$TMP_ROOT/bash.json"
./bin/palari web --check >"$TMP_ROOT/web.json"

python3 - "$TMP_ROOT/fast.json" "$TMP_ROOT/bash.json" "$TMP_ROOT/web.json" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    data = json.load(open(path))
    assert "company_os" in data, path
    company = data["company_os"]
    assert company["workflows"]["active"] == 2, company
    assert company["workflows"]["proposed"] == 0, company
    assert company["workflows"]["errors"] == [], company
    assert len(company["workflows"]["items"]) == 2, company
    workflow_items = {item["id"]: item for item in company["workflows"]["items"]}
    assert workflow_items["WF-0001"]["risk_sources"]["max_declared_risk"] == "R4", workflow_items
    assert workflow_items["WF-0002"]["risk_sources"]["max_declared_risk"] == "R5", workflow_items
    assert workflow_items["WF-0002"]["missing_skills"] == ["privacy:L5"], workflow_items
    assert company["humans"]["active"] == 2, company
    assert company["humans"]["coverage_gaps"] == ["privacy:L5"], company
    gov = company["human_governance"]
    assert gov["open_hgl_estimate"] > 15, gov
    assert gov["r3_decisions_open"] == 1, gov
    assert gov["r4_decisions_open"] == 1, gov
    assert gov["r5_decisions_open"] == 1, gov
    assert gov["missing_skills"] == ["privacy:L5"], gov
    assert "product_governor" in gov["bottlenecks"], gov
    assert "WF-0002 exceeds available weekly HGL" in gov["capacity_warnings"], gov
    assert gov["debt"]["level"] == "high", gov
    assert gov["debt"]["item_count"] >= 2, gov
    assert gov["debt"]["highest_leverage_fix"], gov
    assert gov["errors"] == [], gov
    autonomy = company["autonomy"]
    assert autonomy["yellow_workflows"] == 1, autonomy
    assert autonomy["red_workflows"] == 1, autonomy
    assert company["policy"] == {
        "simulation_only": True,
        "candidates": 0,
        "active_policies": 0,
        "proposed_policies": 0,
        "errors": [],
    }, company
    assert company["broker"] == {
        "real_side_effects_enabled": False,
        "mock_observations": 1,
        "tickets_with_broker_evidence": ["BRK-0200"],
        "errors": [],
    }, company
    assert company["outcomes"] == {"open": 0, "recorded": 0, "invalidated": 0, "errors": []}, company
    assert company["errors"] == [], company
    if not path.endswith("bash.json"):
        cards = company["dashboard_cards"]
        card_map = {card["id"]: card for card in cards}
        required = {
            "human_governance_load",
            "high_risk_decisions",
            "missing_skills",
            "bottlenecks",
            "autonomy_gates",
            "policy_candidates",
            "broker_posture",
            "outcomes",
            "secure_posture",
        }
        assert required <= set(card_map), card_map
        assert card_map["human_governance_load"]["status"] == "bad", card_map
        assert card_map["high_risk_decisions"]["value"] == "1/1/1", card_map
        assert card_map["missing_skills"]["value"] == "1", card_map
        assert card_map["autonomy_gates"]["value"] == "0/1/1", card_map
        assert card_map["policy_candidates"]["detail"].startswith("Simulation-only"), card_map
        assert "observed-only" in card_map["broker_posture"]["value"], card_map
        assert card_map["broker_posture"]["status"] == "ok", card_map
PY

cat >workflows/active/WF-0999-broken-workflow.md <<'EOF'
This active workflow is intentionally malformed for snapshot error coverage.
EOF
mkdir -p reports/evidence/BRK-0201/broker/RUN-BROKEN
printf '{broken\n' >reports/evidence/BRK-0201/broker/RUN-BROKEN/summary.json
cat >outcomes/open/OUT-0999-broken-outcome.md <<'EOF'
This outcome is intentionally malformed for snapshot error coverage.
EOF

./bin/palari snapshot --json >"$TMP_ROOT/errors-fast.json"
PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json >"$TMP_ROOT/errors-bash.json"

python3 - "$TMP_ROOT/errors-fast.json" "$TMP_ROOT/errors-bash.json" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    data = json.load(open(path))
    company = data["company_os"]
    assert company["errors"], company
    assert company["workflows"]["errors"], company
    assert company["human_governance"]["errors"], company
    assert company["broker"]["errors"], company
    assert company["outcomes"]["errors"], company
    assert any("workflow analysis error" in item for item in company["errors"]), company
    assert any("broker summary parse error" in item for item in company["errors"]), company
    assert any("outcome parse error" in item for item in company["errors"]), company
    error_items = [item for item in company["workflows"]["items"] if item.get("status") == "analysis_error"]
    assert len(error_items) == 1, company["workflows"]["items"]
    error_item = error_items[0]
    assert error_item["id"] == "WF-0999-broken-workflow", error_item
    assert error_item["launch_gate"] == "red", error_item
    assert error_item["autonomy_ceiling"] == "simulation_only", error_item
    assert error_item["human_governance_load"] is None, error_item
    assert company["autonomy"]["red_workflows"] >= 2, company["autonomy"]
    assert any("workflow analysis error" in item for item in company["human_governance"]["capacity_warnings"]), company
    if not path.endswith("errors-bash.json"):
        card_map = {card["id"]: card for card in company["dashboard_cards"]}
        assert card_map["human_governance_load"]["status"] == "bad", card_map
        assert card_map["high_risk_decisions"]["status"] == "bad", card_map
        assert card_map["high_risk_decisions"]["value"] == "unknown", card_map
        assert card_map["missing_skills"]["status"] == "bad", card_map
        assert card_map["missing_skills"]["value"] == "unknown", card_map
        assert card_map["bottlenecks"]["status"] == "bad", card_map
        assert card_map["bottlenecks"]["value"] == "unknown", card_map
        assert card_map["autonomy_gates"]["status"] == "bad", card_map
        assert card_map["broker_posture"]["status"] == "bad", card_map
        assert card_map["broker_posture"]["value"] == "unknown", card_map
        assert card_map["outcomes"]["status"] == "bad", card_map
        assert card_map["outcomes"]["value"] == "unknown", card_map
        assert card_map["active_workflows"]["status"] == "bad", card_map
        assert card_map["active_workflows"]["value"] == "unknown", card_map
PY

mv adapters/planning/company_os_snapshot.py "$TMP_ROOT/company_os_snapshot.py.disabled"
./bin/palari snapshot --json >"$TMP_ROOT/helper-missing-fast.json"
PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json >"$TMP_ROOT/helper-missing-bash.json"

python3 - "$TMP_ROOT/helper-missing-fast.json" "$TMP_ROOT/helper-missing-bash.json" <<'PY'
import json
import sys

expected = ["company OS snapshot helper unavailable"]
for path in sys.argv[1:]:
    data = json.load(open(path))
    company = data["company_os"]
    assert company["errors"] == expected, company
    assert company["workflows"]["errors"] == expected, company
    assert company["human_governance"]["errors"] == expected, company
    assert company["human_governance"]["capacity_warnings"] == expected, company
    assert company["policy"]["errors"] == expected, company
    assert company["broker"]["errors"] == expected, company
    assert company["outcomes"]["errors"] == expected, company
    if not path.endswith("helper-missing-bash.json"):
        card_map = {card["id"]: card for card in company["dashboard_cards"]}
        assert card_map["human_governance_load"]["status"] == "bad", card_map
        assert card_map["high_risk_decisions"]["status"] == "bad", card_map
        assert card_map["high_risk_decisions"]["value"] == "unknown", card_map
        assert card_map["missing_skills"]["status"] == "bad", card_map
        assert card_map["missing_skills"]["value"] == "unknown", card_map
        assert card_map["bottlenecks"]["status"] == "bad", card_map
        assert card_map["bottlenecks"]["value"] == "unknown", card_map
        assert card_map["policy_candidates"]["status"] == "bad", card_map
        assert card_map["policy_candidates"]["value"] == "unknown", card_map
        assert card_map["broker_posture"]["status"] == "bad", card_map
        assert card_map["broker_posture"]["value"] == "unknown", card_map
        assert card_map["outcomes"]["status"] == "bad", card_map
        assert card_map["outcomes"]["value"] == "unknown", card_map
        assert card_map["active_workflows"]["status"] == "bad", card_map
        assert card_map["active_workflows"]["value"] == "unknown", card_map
PY

printf 'company-os-snapshot: ok\n'
