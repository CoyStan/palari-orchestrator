#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'company-os-demo: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-company-os-demo.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md decisions/open/*.md decisions/decided/*.md memory/decisions/*.md outcomes/open/*.md outcomes/recorded/*.md goals/active/*.md goals/proposed/*.md goals/closed/*.md

git init -b main >/dev/null
git config user.email "company-os-demo@example.invalid"
git config user.name "Company OS Demo Test"
git add .
git commit -m "company os demo baseline" >/dev/null

./bin/palari demo --company-os >"$TMP_ROOT/demo.out"
grep -Fq "demo: wrote Company OS fixtures" "$TMP_ROOT/demo.out" ||
	fail "demo output missing success line"
grep -Fq "missing skill: privacy:L5" "$TMP_ROOT/demo.out" ||
	fail "demo output missing missing skill"
grep -Fq "policy candidate: run ./bin/palari policy candidates" "$TMP_ROOT/demo.out" ||
	fail "demo output missing policy candidate pointer"

test -f goals/active/GOAL-9004-company-os-demo.md || fail "fallback active goal missing"
test -f workflows/active/WF-9101-growth-beta-experiment.md || fail "growth workflow missing"
test -f workflows/active/WF-9102-support-reply-patterns.md || fail "support workflow missing"
test -f workflows/active/WF-9103-engineering-broker-boundary.md || fail "engineering workflow missing"
test -f humans/active/HUMAN-COS-FOUNDER-founder-general-manager.md || fail "founder human missing"
test -f humans/active/HUMAN-COS-PRODUCT-product-growth-governor.md || fail "product human missing"
test -f humans/active/HUMAN-COS-TECH-technical-security-governor.md || fail "technical human missing"
test -f humans/active/HUMAN-COS-CUSTOMER-customer-brand-governor.md || fail "customer human missing"
test -f humans/proposed/HUMAN-COS-PRIVACY-proposed-privacy-governor.md || fail "proposed privacy human missing"
test -f tickets/open/DPC-9001-company-os-demo-docs-approval-1.md || fail "candidate ticket 1 missing"
test -f decisions/decided/DEC-9001-approve-company-os-demo-docs-change-1.md || fail "decided decision 1 missing"
test -f reports/evidence/DPC-9001/broker/RUN-COMPANY-OS-DEMO/summary.json || fail "broker summary missing"
test -f outcomes/recorded/OUT-9004-company-os-demo-outcome.md || fail "recorded outcome missing"

./bin/palari workflow plan WF-9101 >"$TMP_ROOT/plan-growth.out"
grep -Fq "Workflow: WF-9101 Growth beta experiment" "$TMP_ROOT/plan-growth.out" ||
	fail "growth workflow plan title missing"
grep -Fq "Launch gate: yellow" "$TMP_ROOT/plan-growth.out" ||
	fail "growth workflow should show yellow launch gate"
grep -Fq "Autonomy ceiling: conditional_autonomy" "$TMP_ROOT/plan-growth.out" ||
	fail "growth workflow should show conditional autonomy"
grep -Fq "product_strategy L4: covered by HUMAN-COS-PRODUCT" "$TMP_ROOT/plan-growth.out" ||
	fail "growth workflow should show product coverage"
grep -Fq "product_growth_governor" "$TMP_ROOT/plan-growth.out" ||
	fail "growth workflow should show product bottleneck"

./bin/palari workflow plan WF-9102 >"$TMP_ROOT/plan-support.out"
grep -Fq "Workflow: WF-9102 Support reply patterns" "$TMP_ROOT/plan-support.out" ||
	fail "support workflow plan title missing"
grep -Fq "Launch gate: green" "$TMP_ROOT/plan-support.out" ||
	fail "support workflow should show green launch gate"
grep -Fq "Autonomy ceiling: high_autonomy" "$TMP_ROOT/plan-support.out" ||
	fail "support workflow should show high autonomy"
grep -Fq "customer_support L3: covered by HUMAN-COS-CUSTOMER" "$TMP_ROOT/plan-support.out" ||
	fail "support workflow should show customer support coverage"

./bin/palari workflow plan WF-9103 >"$TMP_ROOT/plan-engineering.out"
grep -Fq "Workflow: WF-9103 Engineering broker boundary" "$TMP_ROOT/plan-engineering.out" ||
	fail "engineering workflow plan title missing"
grep -Fq "Launch gate: red" "$TMP_ROOT/plan-engineering.out" ||
	fail "engineering workflow should show red launch gate"
grep -Fq "Autonomy ceiling: simulation_only" "$TMP_ROOT/plan-engineering.out" ||
	fail "engineering workflow should show simulation-only autonomy"
grep -Fq "privacy L5: covered by missing" "$TMP_ROOT/plan-engineering.out" ||
	fail "engineering workflow missing privacy skill warning"
grep -Fq -- "- privacy:L5" "$TMP_ROOT/plan-engineering.out" ||
	fail "engineering workflow missing privacy skill list item"

./bin/palari policy candidates >"$TMP_ROOT/candidates.out"
grep -Fq "Policy candidate: R1 demo repeated approvals" "$TMP_ROOT/candidates.out" ||
	fail "policy candidate missing"
grep -Fq "Observed: 3 decided R1 demo decisions, 3 chose recommended option 1" "$TMP_ROOT/candidates.out" ||
	fail "policy candidate observation missing"
grep -Fq "Linked outcomes: 1 recorded" "$TMP_ROOT/candidates.out" ||
	fail "policy candidate outcome link missing"

./bin/palari broker evidence DPC-9001 --json >"$TMP_ROOT/broker.json"
python3 - "$TMP_ROOT/broker.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["ticket"] == "DPC-9001"
assert data["real_side_effects_enabled"] is False
assert data["count"] == 1
item = data["items"][0]
assert item["path"] == "reports/evidence/DPC-9001/broker/RUN-COMPANY-OS-DEMO"
assert item["command"] == ["printf", "company os demo broker observation"]
assert item["executed"] is True
assert item["refused"] is False
PY

./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
./bin/palari web --check >"$TMP_ROOT/web.json"
python3 - "$TMP_ROOT/snapshot.json" "$TMP_ROOT/web.json" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    data = json.load(open(path))
    company = data["company_os"]
    assert company["workflows"]["active"] == 3, company
    workflow_items = {item["id"]: item for item in company["workflows"]["items"]}
    assert workflow_items["WF-9101"]["launch_gate"] == "yellow", workflow_items
    assert workflow_items["WF-9101"]["autonomy_ceiling"] == "conditional_autonomy", workflow_items
    assert workflow_items["WF-9102"]["launch_gate"] == "green", workflow_items
    assert workflow_items["WF-9102"]["autonomy_ceiling"] == "high_autonomy", workflow_items
    assert workflow_items["WF-9103"]["launch_gate"] == "red", workflow_items
    assert workflow_items["WF-9103"]["autonomy_ceiling"] == "simulation_only", workflow_items
    assert company["humans"]["active"] == 4, company
    assert company["humans"]["proposed"] == 1, company
    assert company["human_governance"]["missing_skills"] == ["privacy:L5"], company
    assert company["autonomy"]["green_workflows"] == 1, company
    assert company["autonomy"]["yellow_workflows"] == 1, company
    assert company["autonomy"]["red_workflows"] == 1, company
    assert company["policy"]["candidates"] == 1, company
    assert company["broker"]["mock_observations"] == 1, company
    assert company["broker"]["tickets_with_broker_evidence"] == ["DPC-9001"], company
    assert company["outcomes"]["recorded"] == 1, company
    assert company["outcomes"]["open"] == 0, company
    assert company["broker"]["real_side_effects_enabled"] is False, company
PY

if ./bin/palari demo --company-os >"$TMP_ROOT/demo-again.out" 2>&1; then
	fail "second company OS demo run should require --force"
fi
grep -Fq "pass --force to replace demo fixtures" "$TMP_ROOT/demo-again.out" ||
	fail "second run should explain --force"
./bin/palari demo --company-os --force >"$TMP_ROOT/demo-force.out"
grep -Fq "demo: wrote Company OS fixtures" "$TMP_ROOT/demo-force.out" ||
	fail "force run missing success line"

printf 'company-os-demo: ok\n'
