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
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md

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
    assert len(company["workflows"]["items"]) == 2, company
    assert company["humans"]["active"] == 2, company
    gov = company["human_governance"]
    assert gov["open_hgl_estimate"] > 15, gov
    assert gov["r3_decisions_open"] == 1, gov
    assert gov["r4_decisions_open"] == 1, gov
    assert gov["r5_decisions_open"] == 1, gov
    assert gov["missing_skills"] == ["privacy:L5"], gov
    assert "product_governor" in gov["bottlenecks"], gov
    autonomy = company["autonomy"]
    assert autonomy["yellow_workflows"] == 1, autonomy
    assert autonomy["red_workflows"] == 1, autonomy
    assert company["policy"] == {"simulation_only": True, "candidates": 0}, company
    assert company["broker"]["real_side_effects_enabled"] is False, company
PY

printf 'company-os-snapshot: ok\n'
