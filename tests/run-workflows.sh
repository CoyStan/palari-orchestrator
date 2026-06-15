#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'workflows: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-workflows.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md

git init -b main >/dev/null
git config user.email "workflows@example.invalid"
git config user.name "Workflows Test"
git add .
git commit -m "workflows baseline" >/dev/null

./bin/palari init >"$TMP_ROOT/init.out"
test -f workflows/proposed/.gitkeep || fail "init should create workflows/proposed"
test -f workflows/active/.gitkeep || fail "init should create workflows/active"
test -f workflows/closed/.gitkeep || fail "init should create workflows/closed"

./bin/palari workflow create WF-0001 "Improve onboarding activation" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R4 \
	--autonomy-target conditional >"$TMP_ROOT/create.out"

grep -Fq "workflow create: workflows/proposed/WF-0001-improve-onboarding-activation.md" "$TMP_ROOT/create.out" ||
	fail "workflow create path missing"
test -f workflows/proposed/WF-0001-improve-onboarding-activation.md ||
	fail "proposed workflow missing"

./bin/palari workflow list >"$TMP_ROOT/list-proposed.out"
grep -Fq "proposed WF-0001" "$TMP_ROOT/list-proposed.out" ||
	fail "workflow list missing proposed workflow"

./bin/palari workflow show WF-0001 >"$TMP_ROOT/show.out"
grep -Fq "Workflow: WF-0001 - Improve onboarding activation" "$TMP_ROOT/show.out" ||
	fail "workflow show missing title"
grep -Fq "risk_ceiling: R4" "$TMP_ROOT/show.out" ||
	fail "workflow show missing risk ceiling"

python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0001-improve-onboarding-activation.md")
text = path.read_text()
text = text.replace(
    "work_units:\n",
    "work_units:\n"
    "  - WU-0001|research|R1|Analyze onboarding dropoff\n"
    "  - WU-0002|code_change|R2|Implement feature-flagged copy test\n",
)
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R3|choose|product_strategy:L4,analytics:L3|Choose experiment direction|novelty=medium\n"
    "  - R4|approve|technical_governance:L4|Approve production rollout|context=high\n",
)
path.write_text(text)
PY

./bin/palari workflow lint >"$TMP_ROOT/lint.out"
grep -Fq "workflow lint: ok" "$TMP_ROOT/lint.out" ||
	fail "workflow lint should pass"
./bin/palari workflow lint WF-0001 >"$TMP_ROOT/lint-one.out"
grep -Fq "workflow lint: ok for WF-0001" "$TMP_ROOT/lint-one.out" ||
	fail "workflow lint one should pass"

./bin/palari workflow adopt WF-0001 --by founder >"$TMP_ROOT/adopt.out"
grep -Fq "workflow adopt: WF-0001 -> workflows/active/WF-0001-improve-onboarding-activation.md" "$TMP_ROOT/adopt.out" ||
	fail "workflow adopt output missing"
test -f workflows/active/WF-0001-improve-onboarding-activation.md ||
	fail "active workflow missing after adopt"
grep -Fq "status: active" workflows/active/WF-0001-improve-onboarding-activation.md ||
	fail "adopt should set status active"

./bin/palari workflow close WF-0001 --by founder --status achieved >"$TMP_ROOT/close.out"
grep -Fq "workflow close: WF-0001 -> workflows/closed/WF-0001-improve-onboarding-activation.md" "$TMP_ROOT/close.out" ||
	fail "workflow close output missing"
grep -Fq "closed_as: achieved" workflows/closed/WF-0001-improve-onboarding-activation.md ||
	fail "close should record outcome"

if ./bin/palari workflow create WF-0002 "Unknown goal" \
	--goal GOAL-9999 \
	--owner founder >"$TMP_ROOT/unknown-goal.out" 2>&1; then
	fail "workflow with unknown goal should fail"
fi
grep -Fq "goal not found: GOAL-9999" "$TMP_ROOT/unknown-goal.out" ||
	fail "unknown goal diagnostic missing"

cat >workflows/proposed/WF-0003-invalid-decision.md <<'DOC'
---
id: WF-0003
title: Invalid Decision
status: proposed
goal: GOAL-0100
owner: founder
risk_ceiling: R4
autonomy_target: conditional
work_units:
  - WU-0001|research|R1|Research something
expected_decisions:
  - R4|approve|missing_skill|Approve rollout
---

# WF-0003 Invalid Decision
DOC

if ./bin/palari workflow lint WF-0003 >"$TMP_ROOT/bad-decision.out" 2>&1; then
	fail "R4 decision without skill:Lx should fail"
fi
grep -Fq "expected decision lacks skill:Lx" "$TMP_ROOT/bad-decision.out" ||
	fail "missing skill diagnostic absent"
rm -f workflows/proposed/WF-0003-invalid-decision.md

cat >workflows/proposed/WF-0004-invalid-unit.md <<'DOC'
---
id: WF-0004
title: Invalid Unit
status: proposed
goal: GOAL-0100
owner: founder
risk_ceiling: R4
autonomy_target: conditional
work_units:
  - WU-0001|research|R6|Invalid risk
expected_decisions:
---

# WF-0004 Invalid Unit
DOC

if ./bin/palari workflow lint WF-0004 >"$TMP_ROOT/bad-unit.out" 2>&1; then
	fail "work unit with invalid risk should fail"
fi
grep -Fq "work unit WU-0001 invalid risk: R6" "$TMP_ROOT/bad-unit.out" ||
	fail "invalid work unit risk diagnostic absent"
rm -f workflows/proposed/WF-0004-invalid-unit.md

cat >workflows/proposed/WF-0005-r3-unit-warning.md <<'DOC'
---
id: WF-0005
title: R3 Unit Warning
status: proposed
goal: GOAL-0100
owner: founder
risk_ceiling: R3
autonomy_target: conditional
work_units:
  - WU-0001|analysis|R3|Analyze customer-impacting change
expected_decisions:
---

# WF-0005 R3 Unit Warning
DOC

./bin/palari workflow lint WF-0005 >"$TMP_ROOT/r3-unit-warning.out"
grep -Fq "warning: work unit WU-0001 R3 has no expected decision at or above R3" "$TMP_ROOT/r3-unit-warning.out" ||
	fail "R3 work unit warning missing"
grep -Fq "workflow lint: ok for WF-0005" "$TMP_ROOT/r3-unit-warning.out" ||
	fail "R3 work unit warning should not fail lint"
rm -f workflows/proposed/WF-0005-r3-unit-warning.md

cat >workflows/proposed/WF-0006-r4-unit-no-decision.md <<'DOC'
---
id: WF-0006
title: R4 Unit No Decision
status: proposed
goal: GOAL-0100
owner: founder
risk_ceiling: R4
autonomy_target: conditional
work_units:
  - WU-0001|rollout|R4|Roll out a production change
expected_decisions:
---

# WF-0006 R4 Unit No Decision
DOC

if ./bin/palari workflow lint WF-0006 >"$TMP_ROOT/r4-unit-no-decision.out" 2>&1; then
	fail "R4 work unit without expected decision should fail"
fi
grep -Fq "work unit WU-0001 R4 requires expected decision at or above R4" "$TMP_ROOT/r4-unit-no-decision.out" ||
	fail "R4 work unit decision diagnostic missing"
rm -f workflows/proposed/WF-0006-r4-unit-no-decision.md

./bin/palari workflow lint >"$TMP_ROOT/final-lint.out"
grep -Fq "workflow lint: ok" "$TMP_ROOT/final-lint.out" ||
	fail "final workflow lint should pass"

printf 'workflows: ok\n'
