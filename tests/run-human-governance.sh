#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'human-governance: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-human-governance.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari humans/proposed/*.md humans/active/*.md humans/revoked/*.md workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md

git init -b main >/dev/null
git config user.email "humans@example.invalid"
git config user.name "Humans Test"
git add .
git commit -m "humans baseline" >/dev/null

./bin/palari init >"$TMP_ROOT/init.out"
test -f humans/proposed/.gitkeep || fail "init should create humans/proposed"
test -f humans/active/.gitkeep || fail "init should create humans/active"
test -f humans/revoked/.gitkeep || fail "init should create humans/revoked"

./bin/palari human create HUMAN-ALICE Alice \
	--skill product_strategy:L5 \
	--skill analytics:L3 \
	--role product_governor \
	--capacity-hgl 60 \
	--authority-max-risk R5 \
	--may-approve-policy-changes \
	--constraint cannot_self_review_own_work >"$TMP_ROOT/create.out"

grep -Fq "human create: humans/proposed/HUMAN-ALICE-alice.md" "$TMP_ROOT/create.out" ||
	fail "human create path missing"
test -f humans/proposed/HUMAN-ALICE-alice.md || fail "proposed human profile missing"
grep -Fq "weekly_hgl_budget: 60" humans/proposed/HUMAN-ALICE-alice.md ||
	fail "human create should write weekly_hgl_budget"
grep -Fq "max_concurrent_r5: 1" humans/proposed/HUMAN-ALICE-alice.md ||
	fail "human create should write risk capacity fields"

./bin/palari human list >"$TMP_ROOT/list-proposed.out"
grep -Fq "proposed HUMAN-ALICE" "$TMP_ROOT/list-proposed.out" ||
	fail "human list missing proposed profile"

./bin/palari human show HUMAN-ALICE >"$TMP_ROOT/show.out"
grep -Fq "Human: HUMAN-ALICE - Alice" "$TMP_ROOT/show.out" ||
	fail "human show missing title"
grep -Fq "authority_max_risk: R5" "$TMP_ROOT/show.out" ||
	fail "human show missing risk"

./bin/palari human lint >"$TMP_ROOT/lint-proposed.out"
grep -Fq "human lint: ok" "$TMP_ROOT/lint-proposed.out" ||
	fail "human lint should pass for proposed profile"

./bin/palari human adopt HUMAN-ALICE --by founder >"$TMP_ROOT/adopt.out"
grep -Fq "human adopt: HUMAN-ALICE -> humans/active/HUMAN-ALICE-alice.md" "$TMP_ROOT/adopt.out" ||
	fail "human adopt output missing"
test -f humans/active/HUMAN-ALICE-alice.md || fail "active human profile missing"
grep -Fq "status: active" humans/active/HUMAN-ALICE-alice.md ||
	fail "adopt should set status active"

./bin/palari human lint HUMAN-ALICE >"$TMP_ROOT/lint-one.out"
grep -Fq "human lint: ok for HUMAN-ALICE" "$TMP_ROOT/lint-one.out" ||
	fail "human lint one should pass"

./bin/palari human revoke HUMAN-ALICE --by founder >"$TMP_ROOT/revoke.out"
grep -Fq "human revoke: HUMAN-ALICE -> humans/revoked/HUMAN-ALICE-alice.md" "$TMP_ROOT/revoke.out" ||
	fail "human revoke output missing"
test -f humans/revoked/HUMAN-ALICE-alice.md || fail "revoked human profile missing"
grep -Fq "status: revoked" humans/revoked/HUMAN-ALICE-alice.md ||
	fail "revoke should set status revoked"

if ./bin/palari human create HUMAN-BOB Bob \
	--skill product_strategy:6 \
	--role product_governor \
	--capacity-hgl 10 >"$TMP_ROOT/bad-skill-create.out" 2>&1; then
	fail "invalid skill level should fail create"
fi
grep -Fq "invalid skill level" "$TMP_ROOT/bad-skill-create.out" ||
	fail "invalid skill diagnostic missing"

cat >humans/active/HUMAN-CAROL-carol.md <<'DOC'
---
id: HUMAN-CAROL
name: Carol
status: active
roles:
  - security_governor
skills:
  - security_engineering:L5
authority_max_risk: R5
may_approve_policy_changes: false
capacity_weekly_hgl: 20
capacity_open_r3: 2
capacity_open_r4: 1
capacity_open_r5: 1
constraints:
---

# HUMAN-CAROL Carol
DOC

if ./bin/palari human lint HUMAN-CAROL >"$TMP_ROOT/r5-no-policy.out" 2>&1; then
	fail "R5 authority without policy approval flag should fail"
fi
grep -Fq "R5 authority requires may_approve_policy_changes: true" "$TMP_ROOT/r5-no-policy.out" ||
	fail "R5 policy flag diagnostic missing"
rm -f humans/active/HUMAN-CAROL-carol.md

cat >humans/active/HUMAN-DANA-dana.md <<'DOC'
---
id: HUMAN-DANA
name: Dana
status: active
roles:
  - product_governor
skills:
  - product_strategy:L4
authority_max_risk: R4
may_approve_policy_changes: false
capacity_weekly_hgl: many
capacity_open_r3: 2
capacity_open_r4: 1
capacity_open_r5: 0
constraints:
---

# HUMAN-DANA Dana
DOC

if ./bin/palari human lint HUMAN-DANA >"$TMP_ROOT/bad-capacity.out" 2>&1; then
	fail "non-integer capacity should fail"
fi
grep -Fq "capacity_weekly_hgl must be a non-negative integer" "$TMP_ROOT/bad-capacity.out" ||
	fail "capacity diagnostic missing"
rm -f humans/active/HUMAN-DANA-dana.md

git add .
git commit -m "human lifecycle fixture state" >/dev/null

cat >humans/active/HUMAN-GRACE-grace.md <<'DOC'
---
id: HUMAN-GRACE
name: Grace
status: active
roles:
  - operations_governor
skills:
  - operations:L4
authority_max_risk: R4
may_approve_policy_changes: false
capacity_weekly_hgl: 22
capacity_open_r3: 3
capacity_open_r4: 0
capacity_open_r5: 0
constraints:
---

# HUMAN-GRACE Grace
DOC
git add humans/active/HUMAN-GRACE-grace.md
git commit -m "legacy human capacity fixture" >/dev/null

./bin/palari workflow create WF-0191 "Legacy capacity migration guard" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R4 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0191-legacy-capacity-migration-guard.md")
text = path.read_text()
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R4|approve|operations:L4|Approve operations launch boundary\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0191 --by founder >/dev/null
git add workflows/active/WF-0191-legacy-capacity-migration-guard.md
git commit -m "legacy capacity workflow fixture" >/dev/null

./bin/palari burden score WF-0191 --json >"$TMP_ROOT/legacy-capacity-before.json"
python3 - "$TMP_ROOT/legacy-capacity-before.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
coverage = data["decisions"][0]["coverage"][0]
assert coverage["covered_by"] == ["HUMAN-GRACE"], data
assert coverage["at_capacity"] == [], data
assert data["capacity"]["risk_capacity_failures"] == [], data
assert data["launch_gate"] == "yellow", data
PY

git_before="$(git status --porcelain | sort)"
./bin/palari human migrate-capacity --check >"$TMP_ROOT/migrate-check.out"
git_after="$(git status --porcelain | sort)"
[[ "$git_before" == "$git_after" ]] ||
	fail "human migrate-capacity --check should not modify files"
grep -Fq "needs migration: humans/active/HUMAN-GRACE-grace.md" "$TMP_ROOT/migrate-check.out" ||
	fail "migrate check should report legacy profile"
grep -Fq "1 profile(s) need migration" "$TMP_ROOT/migrate-check.out" ||
	fail "migrate check count missing"
./bin/palari human lint HUMAN-GRACE >"$TMP_ROOT/legacy-lint.out"
grep -Fq "human lint: ok for HUMAN-GRACE" "$TMP_ROOT/legacy-lint.out" ||
	fail "legacy capacity profile should remain lint-compatible"

printf 'dirty\n' >dirty-source.txt
if ./bin/palari human migrate-capacity --write >"$TMP_ROOT/migrate-dirty.out" 2>&1; then
	fail "human migrate-capacity --write should refuse a dirty repo"
fi
grep -Fq "canonical repo has" "$TMP_ROOT/migrate-dirty.out" ||
	fail "migrate dirty-repo diagnostic missing"
rm -f dirty-source.txt

./bin/palari human migrate-capacity --write >"$TMP_ROOT/migrate-write.out"
grep -Fq "migrated: humans/active/HUMAN-GRACE-grace.md" "$TMP_ROOT/migrate-write.out" ||
	fail "migrate write should report migrated profile"
grep -Fq "weekly_hgl_budget: 22" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should set weekly_hgl_budget"
grep -Fq "current_weekly_hgl: 0" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should set current_weekly_hgl"
grep -Fq "max_concurrent_r3: 3" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should set max_concurrent_r3 from legacy capacity_open_r3"
grep -Fq "max_concurrent_r4: 1" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should preserve legacy capacity_open_r4 zero as unspecified capacity"
grep -Fq "max_concurrent_r5: 1" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should preserve legacy capacity_open_r5 zero as unspecified capacity"
grep -Fq "current_open_r5: 0" humans/active/HUMAN-GRACE-grace.md ||
	fail "migrate write should set current_open_r5"
if grep -Fq "capacity_" humans/active/HUMAN-GRACE-grace.md; then
	fail "migrate write should remove deprecated capacity fields"
fi
./bin/palari burden score WF-0191 --json >"$TMP_ROOT/legacy-capacity-after.json"
python3 - "$TMP_ROOT/legacy-capacity-before.json" "$TMP_ROOT/legacy-capacity-after.json" <<'PY'
import json
import sys

before = json.load(open(sys.argv[1]))
after = json.load(open(sys.argv[2]))
for data in (after,):
    coverage = data["decisions"][0]["coverage"][0]
    assert coverage["covered_by"] == ["HUMAN-GRACE"], data
    assert coverage["at_capacity"] == [], data
    assert data["capacity"]["risk_capacity_failures"] == [], data
assert before["launch_gate"] == after["launch_gate"] == "yellow", (before, after)
assert before["coverage_failures"] == after["coverage_failures"] == [], (before, after)
PY
./bin/palari human migrate-capacity --check >"$TMP_ROOT/migrate-clean.out"
grep -Fq "ok (no deprecated capacity fields found)" "$TMP_ROOT/migrate-clean.out" ||
	fail "migrate check should be clean after write"
./bin/palari human lint HUMAN-GRACE >"$TMP_ROOT/migrated-lint.out"
grep -Fq "human lint: ok for HUMAN-GRACE" "$TMP_ROOT/migrated-lint.out" ||
	fail "migrated profile should lint"
rm -f humans/active/HUMAN-GRACE-grace.md
rm -f workflows/active/WF-0191-legacy-capacity-migration-guard.md
git add -u humans/active/HUMAN-GRACE-grace.md workflows/active/WF-0191-legacy-capacity-migration-guard.md
git commit -m "remove legacy migration fixture" >/dev/null

cat >humans/active/HUMAN-EMPTY-empty.md <<'DOC'
---
id: HUMAN-EMPTY
name: Empty
status: active
roles:
  - operations_governor
skills:
  - operations:L4
authority_max_risk: R4
may_approve_policy_changes: false
capacity_weekly_hgl:
capacity_open_r3:
capacity_open_r4:
capacity_open_r5:
constraints:
---

# HUMAN-EMPTY Empty
DOC
git add humans/active/HUMAN-EMPTY-empty.md
git commit -m "empty legacy capacity fixture" >/dev/null

./bin/palari human migrate-capacity --check >"$TMP_ROOT/migrate-empty-check.out"
grep -Fq "needs migration: humans/active/HUMAN-EMPTY-empty.md" "$TMP_ROOT/migrate-empty-check.out" ||
	fail "migrate check should report empty deprecated capacity keys"
./bin/palari human migrate-capacity --write >"$TMP_ROOT/migrate-empty-write.out"
grep -Fq "migrated: humans/active/HUMAN-EMPTY-empty.md" "$TMP_ROOT/migrate-empty-write.out" ||
	fail "migrate write should report empty deprecated capacity profile"
grep -Fq "weekly_hgl_budget: 0" humans/active/HUMAN-EMPTY-empty.md ||
	fail "empty weekly legacy capacity should migrate to default weekly budget"
grep -Fq "max_concurrent_r3: 6" humans/active/HUMAN-EMPTY-empty.md ||
	fail "empty legacy R3 capacity should migrate to default R3 capacity"
grep -Fq "max_concurrent_r4: 2" humans/active/HUMAN-EMPTY-empty.md ||
	fail "empty legacy R4 capacity should migrate to default R4 capacity"
grep -Fq "max_concurrent_r5: 1" humans/active/HUMAN-EMPTY-empty.md ||
	fail "empty legacy R5 capacity should migrate to default R5 capacity"
if grep -Eq "^capacity_(weekly_hgl|open_r[345]):" humans/active/HUMAN-EMPTY-empty.md; then
	fail "migrate write should remove empty deprecated capacity keys"
fi
./bin/palari human migrate-capacity --check >"$TMP_ROOT/migrate-empty-clean.out"
grep -Fq "ok (no deprecated capacity fields found)" "$TMP_ROOT/migrate-empty-clean.out" ||
	fail "migrate check should be clean after removing empty deprecated keys"
./bin/palari human lint HUMAN-EMPTY >"$TMP_ROOT/migrated-empty-lint.out"
grep -Fq "human lint: ok for HUMAN-EMPTY" "$TMP_ROOT/migrated-empty-lint.out" ||
	fail "profile migrated from empty deprecated keys should lint"
rm -f humans/active/HUMAN-EMPTY-empty.md

cat >humans/active/HUMAN-ERIN-erin.md <<'DOC'
---
id: HUMAN-ERIN
name: Erin
status: active
roles:
  - product_governor
skills:
  - product_strategy:L4
authority_max_risk: R4
may_approve_policy_changes: false
weekly_hgl_budget: 10
current_weekly_hgl: 11
max_concurrent_r3: 2
current_open_r3: 0
max_concurrent_r4: 1
current_open_r4: 0
max_concurrent_r5: 0
current_open_r5: 0
constraints:
---

# HUMAN-ERIN Erin
DOC

if ./bin/palari human lint HUMAN-ERIN >"$TMP_ROOT/over-weekly.out" 2>&1; then
	fail "current weekly HGL over budget should fail"
fi
grep -Fq "current_weekly_hgl exceeds weekly_hgl_budget" "$TMP_ROOT/over-weekly.out" ||
	fail "weekly capacity diagnostic missing"
rm -f humans/active/HUMAN-ERIN-erin.md

cat >humans/active/HUMAN-FRANK-frank.md <<'DOC'
---
id: HUMAN-FRANK
name: Frank
status: active
roles:
  - privacy_governor
skills:
  - privacy:L5
authority_max_risk: R5
may_approve_policy_changes: true
weekly_hgl_budget: 40
current_weekly_hgl: 0
max_concurrent_r3: 2
current_open_r3: 0
max_concurrent_r4: 1
current_open_r4: 0
max_concurrent_r5: 1
current_open_r5: 2
constraints:
---

# HUMAN-FRANK Frank
DOC

if ./bin/palari human lint HUMAN-FRANK >"$TMP_ROOT/over-risk.out" 2>&1; then
	fail "current open risk count over max should fail"
fi
grep -Fq "current_open_r5 exceeds max_concurrent_r5" "$TMP_ROOT/over-risk.out" ||
	fail "risk capacity diagnostic missing"
rm -f humans/active/HUMAN-FRANK-frank.md

./bin/palari human lint >"$TMP_ROOT/final-lint.out"
grep -Fq "human lint: ok" "$TMP_ROOT/final-lint.out" ||
	fail "final human lint should pass"

./bin/palari human create HUMAN-FOUNDER Founder \
	--skill product_strategy:L5 \
	--skill analytics:L3 \
	--skill operations:L3 \
	--role product_governor \
	--role analytics_reviewer \
	--role operations_governor \
	--capacity-hgl 80 \
	--authority-max-risk R5 \
	--may-approve-policy-changes >/dev/null
./bin/palari human adopt HUMAN-FOUNDER --by founder >/dev/null
./bin/palari human create HUMAN-PRIVACY-LOW "Privacy Low" \
	--skill privacy:L3 \
	--role privacy_governor \
	--capacity-hgl 40 \
	--authority-max-risk R3 >/dev/null
./bin/palari human adopt HUMAN-PRIVACY-LOW --by founder >/dev/null

./bin/palari workflow create WF-0100 "Launch governed beta" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R5 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0100-launch-governed-beta.md")
text = path.read_text()
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R5|approve|privacy:L5|Approve privacy boundary\n"
    "  - R3|choose|privacy:L3|Choose privacy review posture\n"
    "  - R4|approve|technical_governance:L4|Approve production controls\n"
    "  - R3|choose|product_strategy:L4,analytics:L3,operations:L3|Choose launch operating plan\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0100 --by founder >/dev/null

./bin/palari human org-plan >"$TMP_ROOT/org-plan.out"
grep -Fq "Minimum viable human company for active workflows:" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan title missing"
grep -Fq "privacy_governor L5: privacy for R5 (missing; missing)" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan privacy missing row missing"
grep -Fq "privacy_governor L3: privacy for R3 (thin; HUMAN-PRIVACY-LOW)" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan lower-risk privacy coverage row missing"
grep -Fq "technical_governor L4: technical_governance for R4 (missing; missing)" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan technical missing row missing"
grep -Fq "product_governor L4: product_strategy for R3 (thin; HUMAN-FOUNDER)" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan product thin row missing"
grep -Fq "HUMAN-FOUNDER covers 3 required governance role(s)" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan concentration risk missing"
grep -Fq "Recommendation:" "$TMP_ROOT/org-plan.out" ||
	fail "org-plan recommendation missing"

./bin/palari human org-plan --json >"$TMP_ROOT/org-plan.json"
python3 - "$TMP_ROOT/org-plan.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["active_workflow_count"] == 1, data
requirements = {
    (item["role"], item["skill"], item["level"], item["risk"]): item
    for item in data["requirements"]
}
assert requirements[("privacy_governor", "privacy", "L5", "R5")]["status"] == "missing", requirements
assert requirements[("privacy_governor", "privacy", "L5", "R5")]["covered_by"] == [], requirements
assert requirements[("privacy_governor", "privacy", "L3", "R3")]["covered_by"] == ["HUMAN-PRIVACY-LOW"], requirements
assert requirements[("technical_governor", "technical_governance", "L4", "R4")]["status"] == "missing", requirements
assert requirements[("product_governor", "product_strategy", "L4", "R3")]["covered_by"] == ["HUMAN-FOUNDER"], requirements
assert requirements[("analytics_reviewer", "analytics", "L3", "R3")]["status"] == "thin", requirements
assert requirements[("operations_governor", "operations", "L3", "R3")]["status"] == "thin", requirements
assert data["missing_requirements"] == 2, data
assert data["thin_requirements"] == 4, data
assert data["concentration_risks"][0]["human"] == "HUMAN-FOUNDER", data
assert "privacy_governor" in data["recommendation"], data
PY

printf 'human-governance: ok\n'
