#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'human-governance-load: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-human-governance-load.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md

git init -b main >/dev/null
git config user.email "hgl@example.invalid"
git config user.name "HGL Test"
git add .
git commit -m "hgl baseline" >/dev/null

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

./bin/palari burden score WF-0001 >"$TMP_ROOT/score.out"
grep -Fq "human_governance_load: 15" "$TMP_ROOT/score.out" ||
	fail "expected deterministic HGL 15"
grep -Fq "  R3: 1" "$TMP_ROOT/score.out" || fail "R3 count missing"
grep -Fq "  R4: 1" "$TMP_ROOT/score.out" || fail "R4 count missing"
grep -Fq "launch_gate: yellow" "$TMP_ROOT/score.out" || fail "expected yellow launch gate"
grep -Fq "autonomy_ceiling: human_led" "$TMP_ROOT/score.out" || fail "expected human-led autonomy"
grep -Fq "product_governor" "$TMP_ROOT/score.out" || fail "expected bottleneck role"

./bin/palari burden score WF-0001 --json >"$TMP_ROOT/score.json"
python3 - "$TMP_ROOT/score.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["workflow"] == "WF-0001"
assert data["human_governance_load"] == 15
assert data["expected_decisions"]["R3"] == 1
assert data["expected_decisions"]["R4"] == 1
assert data["launch_gate"] == "yellow"
assert data["autonomy_ceiling"] == "human_led"
assert data["missing_skills"] == []
PY

./bin/palari human coverage WF-0001 --json >"$TMP_ROOT/coverage.json"
python3 - "$TMP_ROOT/coverage.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
required = data["required_skills"]
assert required["product_strategy"] == "L4"
assert required["analytics"] == "L3"
assert required["technical_governance"] == "L4"
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
./bin/palari burden score WF-0002 --json >"$TMP_ROOT/missing.json"
python3 - "$TMP_ROOT/missing.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["expected_decisions"]["R5"] == 1
assert data["launch_gate"] == "red"
assert data["autonomy_ceiling"] == "simulation_only"
assert data["missing_skills"] == ["privacy:L5"]
assert data["human_governance_load"] > 20
PY

printf 'human-governance-load: ok\n'

