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

mkdir -p outcomes/recorded
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
recorded_by: founder
recorded_at: 2026-01-01T00:00:00Z
created: 2026-01-01
updated: 2026-01-01
---

# OUT-9000 Docs outcome
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
grep -Fq "Linked outcomes: 1 recorded" "$TMP_ROOT/candidates.out" ||
	fail "linked outcome count missing"
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
assert candidate["suggested_mode"] == "simulation"
assert candidate["expected_hgl_reduction"] == 3
assert candidate["linked_outcome_count"] == 1
assert candidate["linked_outcomes"][0]["id"] == "OUT-9000"
assert data["skipped"]["high_risk_or_governance"] == 3
PY

policy_files="$(find policies -type f -name '*.md' | wc -l | tr -d ' ')"
[[ "$policy_files" == "0" ]] || fail "policy candidates must not create policy files"

rm -f decisions/decided/*.md
./bin/palari policy candidates >"$TMP_ROOT/empty.out"
grep -Fq "No conservative policy candidates found." "$TMP_ROOT/empty.out" ||
	fail "empty candidate output missing"

printf 'policy-candidates: ok\n'
