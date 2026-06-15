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

./bin/palari workflow create WF-0003 "Evidence weighting" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R5 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0003-evidence-weighting.md")
text = path.read_text()
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R5|approve|product_strategy:L5|Strong evidence check|evidence=strong\n"
    "  - R5|approve|product_strategy:L5|Normal evidence check|evidence=normal\n"
    "  - R5|approve|product_strategy:L5|Unknown evidence check|evidence=unexpected_label\n"
    "  - R5|approve|product_strategy:L5|Weak evidence check|evidence=weak\n"
    "  - R5|approve|product_strategy:L5|No evidence check|evidence=none_or_unknown\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0003 --by founder >/dev/null
./bin/palari burden score WF-0003 --json >"$TMP_ROOT/evidence-weighting.json"
python3 - "$TMP_ROOT/evidence-weighting.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
scores = {row["title"]: row["score"] for row in data["decisions"]}
strong = scores["Strong evidence check"]
normal = scores["Normal evidence check"]
unknown = scores["Unknown evidence check"]
weak = scores["Weak evidence check"]
none = scores["No evidence check"]
assert strong < normal < weak < none, scores
assert unknown == normal, scores
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
assert data["coverage_failures"] == ["privacy:L5 has no active human candidates"]
assert data["human_governance_load"] > 20
PY

cat >humans/active/HUMAN-PRIVACY-JR-privacy-jr.md <<'DOC'
---
id: HUMAN-PRIVACY-JR
name: Privacy Junior
status: active
roles:
  - privacy_reviewer
skills:
  - privacy:L5
authority_max_risk: R2
may_approve_policy_changes: false
weekly_hgl_budget: 60
current_weekly_hgl: 0
max_concurrent_r3: 6
current_open_r3: 0
max_concurrent_r4: 2
current_open_r4: 0
max_concurrent_r5: 1
current_open_r5: 0
constraints:
---

# HUMAN-PRIVACY-JR Privacy Junior
DOC

./bin/palari burden score WF-0002 --json >"$TMP_ROOT/under-authorized.json"
python3 - "$TMP_ROOT/under-authorized.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
row = data["decisions"][0]["coverage"][0]
assert row["covered_by"] == []
assert row["under_authorized"] == ["HUMAN-PRIVACY-JR"]
assert row["underleveled"] == []
assert row["at_capacity"] == []
assert data["missing_skills"] == ["privacy:L5"]
assert data["coverage_failures"] == ["privacy:L5 has candidates but none with R5 authority"]
assert data["launch_gate"] == "red"
PY

rm -f humans/active/HUMAN-PRIVACY-JR-privacy-jr.md
cat >humans/active/HUMAN-PRIVACY-NOPOLICY-privacy-no-policy.md <<'DOC'
---
id: HUMAN-PRIVACY-NOPOLICY
name: Privacy No Policy
status: active
roles:
  - privacy_governor
skills:
  - privacy:L5
authority_max_risk: R5
may_approve_policy_changes: false
weekly_hgl_budget: 60
current_weekly_hgl: 0
max_concurrent_r3: 6
current_open_r3: 0
max_concurrent_r4: 2
current_open_r4: 0
max_concurrent_r5: 1
current_open_r5: 0
constraints:
---

# HUMAN-PRIVACY-NOPOLICY Privacy No Policy
DOC

./bin/palari burden score WF-0002 --json >"$TMP_ROOT/r5-no-policy.json"
python3 - "$TMP_ROOT/r5-no-policy.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
row = data["decisions"][0]["coverage"][0]
assert row["covered_by"] == []
assert row["under_authorized"] == ["HUMAN-PRIVACY-NOPOLICY"]
assert data["missing_skills"] == ["privacy:L5"]
assert data["launch_gate"] == "red"
PY

rm -f humans/active/HUMAN-PRIVACY-NOPOLICY-privacy-no-policy.md
cat >humans/active/HUMAN-PRIVACY-FULL-privacy-full.md <<'DOC'
---
id: HUMAN-PRIVACY-FULL
name: Privacy Full
status: active
roles:
  - privacy_governor
skills:
  - privacy:L5
authority_max_risk: R5
may_approve_policy_changes: true
weekly_hgl_budget: 60
current_weekly_hgl: 0
max_concurrent_r3: 6
current_open_r3: 0
max_concurrent_r4: 2
current_open_r4: 0
max_concurrent_r5: 1
current_open_r5: 1
constraints:
---

# HUMAN-PRIVACY-FULL Privacy Full
DOC

./bin/palari burden score WF-0002 --json >"$TMP_ROOT/at-capacity.json"
python3 - "$TMP_ROOT/at-capacity.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
row = data["decisions"][0]["coverage"][0]
assert row["covered_by"] == []
assert row["at_capacity"] == ["HUMAN-PRIVACY-FULL"]
assert data["coverage_failures"] == ["privacy:L5 has authorized candidates but all are at risk capacity"]
assert data["launch_gate"] == "red"
PY

python3 - <<'PY'
from pathlib import Path

path = Path("humans/active/HUMAN-PRIVACY-FULL-privacy-full.md")
text = path.read_text()
text = text.replace("current_open_r5: 1", "current_open_r5: 0")
path.write_text(text)
PY

./bin/palari burden score WF-0002 --json >"$TMP_ROOT/r5-covered.json"
python3 - "$TMP_ROOT/r5-covered.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
row = data["decisions"][0]["coverage"][0]
assert row["covered_by"] == ["HUMAN-PRIVACY-FULL"]
assert row["under_authorized"] == []
assert row["underleveled"] == []
assert row["at_capacity"] == []
assert data["missing_skills"] == []
assert data["coverage_failures"] == []
assert data["launch_gate"] == "green"
assert data["autonomy_ceiling"] == "simulation_only"
PY

printf 'human-governance-load: ok\n'
