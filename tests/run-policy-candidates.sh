#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'policy-candidates: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-policy-candidates.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari decisions/open/*.md decisions/decided/*.md memory/decisions/*.md policies/proposed/*.md policies/active/*.md policies/revoked/*.md
mkdir -p decisions/open decisions/decided policies/proposed policies/active policies/revoked

git init -b main >/dev/null
git config user.email "policy-candidates@example.invalid"
git config user.name "Policy Candidates Test"
git add .
git commit -m "policy candidates baseline" >/dev/null

for i in 1 2 3; do
	./bin/palari ticket create "DOC-000$i" "Docs approval $i" \
		--stream docs \
		--risk R1 \
		--priority P2 \
		--allowed README.md \
		--verify "test -f README.md" >/dev/null
	./bin/palari decide create "DEC-000$i" "Approve docs-only change $i" \
		--ticket "DOC-000$i" \
		--option "Approve docs-only change" \
		--option "Request more review" \
		--recommend 1 >/dev/null
	./bin/palari decide record "DEC-000$i" --choice 1 --by founder --note "No changes needed" >/dev/null
done

./bin/palari ticket create "DOC-0010" "Docs override" \
	--stream docs \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--verify "test -f README.md" >/dev/null
./bin/palari decide create "DEC-0010" "Override docs-only change" \
	--ticket "DOC-0010" \
	--option "Approve docs-only change" \
	--option "Request more review" \
	--recommend 1 >/dev/null
./bin/palari decide record "DEC-0010" --choice 2 --by founder --note "Human override requested more review" >/dev/null

for i in 4 5 6; do
	./bin/palari ticket create "SEC-000$i" "Security approval $i" \
		--stream security \
		--risk R4 \
		--priority P2 \
		--allowed README.md \
		--verify "test -f README.md" \
		--review \
		--human >/dev/null
	./bin/palari decide create "DEC-000$i" "Approve security change $i" \
		--ticket "SEC-000$i" \
		--option "Approve security change" \
		--option "Escalate" \
		--recommend 1 >/dev/null
	./bin/palari decide record "DEC-000$i" --choice 1 --by founder --note "High risk remains human-led" >/dev/null
done

mkdir -p outcomes/recorded reports/evidence/DOC-0001
printf 'reviewed docs evidence\n' >reports/evidence/DOC-0001/outcome.log
cat >outcomes/recorded/OUT-9000-docs-outcome.md <<'DOC'
---
id: OUT-9000
title: Docs outcome
status: observed
lifecycle: recorded
workflow:
goal:
ticket: DOC-0001
decision: DEC-0001
linked_evidence:
  - reports/evidence/DOC-0001/outcome.log
metric_name: docs_completion_rate
metric_before: 0.70
metric_after: 0.80
metric_delta: 0.10
risk_predicted: R1
risk_actual: R1
hgl_predicted: 3
hgl_actual: 1
human_decisions_predicted: 1
human_decisions_actual: 1
review_outcome: passed
rollback_used: false
policy_candidate: true
notes: useful repeated docs outcome
recorded_by: founder
recorded_at: 2026-01-01T00:00:00Z
created: 2026-01-01
updated: 2026-01-01
---

# OUT-9000 Docs outcome
DOC

cat >outcomes/recorded/OUT-9001-docs-rollback.md <<'DOC'
---
id: OUT-9001
title: Docs rollback outcome
status: invalidated
lifecycle: recorded
workflow:
goal:
ticket: DOC-0002
decision: DEC-0002
linked_evidence:
metric_name: docs_completion_rate
metric_before: 0.80
metric_after: 0.75
metric_delta: -0.05
risk_predicted: R1
risk_actual: R2
hgl_predicted: 1
hgl_actual: 4
human_decisions_predicted: 1
human_decisions_actual: 2
review_outcome: failed
rollback_used: true
policy_candidate: false
notes: rollback should lower candidate confidence
recorded_by: founder
recorded_at: 2026-01-01T00:00:00Z
created: 2026-01-01
updated: 2026-01-01
---

# OUT-9001 Docs rollback outcome
DOC

git_before="$(git status --porcelain | sort)"
./bin/palari policy candidates >"$TMP_ROOT/candidates.out"
git_after="$(git status --porcelain | sort)"
[[ "$git_before" == "$git_after" ]] ||
	fail "policy candidates mutated repository state"

grep -Fq "Policy candidate: R1 docs repeated approvals" "$TMP_ROOT/candidates.out" ||
	fail "R1 docs candidate missing"
grep -Fq "Observed: 3 decided R1 docs decisions, 3 chose recommended option 1" "$TMP_ROOT/candidates.out" ||
	fail "candidate observation missing"
grep -Fq "Suggested mode: simulation" "$TMP_ROOT/candidates.out" ||
	fail "simulation mode missing"
grep -Fq "Expected HGL reduction: 3" "$TMP_ROOT/candidates.out" ||
	fail "HGL reduction missing"
grep -Fq "Approval rate: 75% (3/4)" "$TMP_ROOT/candidates.out" ||
	fail "approval rate missing"
grep -Fq "Override rate: 25% (1/4)" "$TMP_ROOT/candidates.out" ||
	fail "override rate missing"
grep -Fq "Linked outcomes: 2 recorded" "$TMP_ROOT/candidates.out" ||
	fail "linked outcome count missing"
grep -Fq "Successful outcomes: 1 recorded" "$TMP_ROOT/candidates.out" ||
	fail "successful outcome count missing"
grep -Fq "Outcome success rate: 50% (1/2)" "$TMP_ROOT/candidates.out" ||
	fail "outcome success rate missing"
grep -Fq "Rollback/failure rate: 50% (1/2)" "$TMP_ROOT/candidates.out" ||
	fail "rollback/failure rate missing"
grep -Fq "Evidence signal: linked_outcome_evidence" "$TMP_ROOT/candidates.out" ||
	fail "evidence signal missing"
grep -Fq "Confidence: low (50)" "$TMP_ROOT/candidates.out" ||
	fail "confidence output missing"
grep -Fq "Reason: 3 docs approvals; 1 overrides; 1/2 successful outcomes; 1 rollback/failure outcomes" "$TMP_ROOT/candidates.out" ||
	fail "candidate reason missing"
grep -Fq "./bin/palari policy create POL-DOCS-R1-AUTO" "$TMP_ROOT/candidates.out" ||
	fail "next policy create command missing"
if grep -Fq "R4 security" "$TMP_ROOT/candidates.out"; then
	fail "R4 decisions must not be suggested for auto-acceptance"
fi

./bin/palari policy candidates --json >"$TMP_ROOT/candidates.json"
python3 - "$TMP_ROOT/candidates.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["simulation_only"] is True
assert data["created_policy_files"] is False
assert data["candidate_count"] == 1
candidate = data["candidates"][0]
assert candidate["id"] == "POL-DOCS-R1-AUTO"
assert candidate["risk"] == "R1"
assert all(item["risk"] in {"R0", "R1", "R2"} for item in data["candidates"])
assert candidate["kind"] == "docs"
assert candidate["decision_count"] == 3
assert candidate["similar_decision_count"] == 4
assert candidate["approval_count"] == 3
assert candidate["override_count"] == 1
assert candidate["human_approval_rate"] == 0.75
assert candidate["human_override_rate"] == 0.25
assert candidate["suggested_mode"] == "simulation"
assert candidate["expected_hgl_reduction"] == 3
assert candidate["linked_outcome_count"] == 2
assert candidate["successful_outcome_count"] == 1
assert candidate["failed_or_rollback_outcome_count"] == 1
assert candidate["rollback_outcome_count"] == 1
assert candidate["invalidated_outcome_count"] == 1
assert candidate["outcome_success_rate"] == 0.5
assert candidate["rollback_failure_rate"] == 0.5
assert candidate["linked_evidence_count"] == 1
assert candidate["evidence_signal"] == "linked_outcome_evidence"
assert candidate["confidence"] == "low"
assert candidate["confidence_score"] == 50
assert "1 overrides" in candidate["reason"]
assert len(candidate["override_examples"]) == 1
assert candidate["linked_outcomes"][0]["id"] == "OUT-9000"
assert candidate["linked_outcomes"][0]["review_outcome"] == "passed"
assert candidate["linked_outcomes"][0]["metric_delta"] == "0.10"
assert candidate["linked_outcomes"][0]["policy_candidate"] == "true"
assert {item["id"] for item in candidate["linked_outcomes"]} == {"OUT-9000", "OUT-9001"}
assert data["skipped"]["high_risk_or_governance"] == 3
assert data["skipped"]["not_matching_recommendation"] == 1
PY

policy_files="$(find policies -type f -name '*.md' | wc -l | tr -d ' ')"
[[ "$policy_files" == "0" ]] || fail "policy candidates must not create policy files"

rm -f decisions/decided/*.md
./bin/palari policy candidates >"$TMP_ROOT/empty.out"
grep -Fq "No conservative policy candidates found." "$TMP_ROOT/empty.out" ||
	fail "empty candidate output missing"

printf 'policy-candidates: ok\n'
