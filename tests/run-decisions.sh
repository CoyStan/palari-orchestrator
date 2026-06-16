#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'decisions: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* goals decisions memory/decisions/*.md workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md outcomes/open/*.md outcomes/recorded/*.md policies/proposed/*.md policies/active/*.md policies/revoked/*.md
mkdir -p goals/active decisions/open decisions/decided

git init -b main >/dev/null
git config user.email "decisions@example.invalid"
git config user.name "Decisions Test"
git add .
git commit -m "decisions baseline" >/dev/null

# A decision needs at least two options.
if ./bin/palari decide create DEC-0001 "One option" --option "Only path" >/dev/null 2>&1; then
	fail "single-option decision should be rejected"
fi

# Create a valid decision.
./bin/palari decide create DEC-0001 "Pick storage backend" \
	--option "SQLite (simple, single file)" \
	--option "Postgres (heavier, multi-user)" \
	--recommend 1 --default 1 --respond-by 2099-01-01 >"$TMP_ROOT/create.out"
grep -Fq "decide create: decisions/open/DEC-0001-pick-storage-backend.md" "$TMP_ROOT/create.out" ||
	fail "decide create did not write the open decision file"
grep -Fq "recommended_option: 1" decisions/open/DEC-0001-*.md ||
	fail "decision frontmatter missing recommendation"

./bin/palari goal create GOAL-0100 "Decision inbox goal" \
	--owner founder \
	--success "Decision inbox shows workflow and open decision artifacts" >/dev/null
./bin/palari human create HUMAN-ALICE Alice \
	--skill technical_governance:L4 \
	--role technical_governor \
	--capacity-hgl 50 \
	--authority-max-risk R4 >/dev/null
./bin/palari human adopt HUMAN-ALICE --by founder >/dev/null
./bin/palari workflow create WF-0001 "Decision inbox workflow" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R5 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-0001-decision-inbox-workflow.md")
text = path.read_text()
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R5|approve|privacy:L5|Approve privacy policy boundary|novelty=high|ambiguity=high|irreversibility=high\n"
    "  - R4|approve|technical_governance:L4|Approve production rollout|context=high\n",
)
path.write_text(text)
PY
./bin/palari workflow adopt WF-0001 --by founder >/dev/null

git_state_before="$(git status --porcelain | sort)"
./bin/palari decide inbox >"$TMP_ROOT/inbox.out"
git_state_after="$(git status --porcelain | sort)"
[[ "$git_state_before" == "$git_state_after" ]] ||
	fail "decide inbox mutated repository state"
grep -Fq "Decision Inbox" "$TMP_ROOT/inbox.out" ||
	fail "inbox heading missing"
grep -Fq "R5: 1 decision" "$TMP_ROOT/inbox.out" ||
	fail "inbox R5 count missing"
grep -Fq "R4: 1 decision" "$TMP_ROOT/inbox.out" ||
	fail "inbox R4 count missing"
grep -Fq "R0: 1 decision" "$TMP_ROOT/inbox.out" ||
	fail "inbox open decision count missing"
grep -Fq "Approve privacy policy boundary [workflow_expected_decision]" "$TMP_ROOT/inbox.out" ||
	fail "inbox missing workflow expected decision"
grep -Fq "skills: privacy L5" "$TMP_ROOT/inbox.out" ||
	fail "inbox missing required skill"
grep -Fq "coverage: missing_skill" "$TMP_ROOT/inbox.out" ||
	fail "inbox missing coverage status"
grep -Fq "Pick storage backend [open_decision]" "$TMP_ROOT/inbox.out" ||
	fail "inbox missing open decision artifact"
grep -Fq "Read-only: no decisions were created or recorded." "$TMP_ROOT/inbox.out" ||
	fail "inbox read-only note missing"

./bin/palari decide inbox --json >"$TMP_ROOT/inbox.json"
python3 - "$TMP_ROOT/inbox.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["read_only"] is True
assert data["created_or_recorded_decisions"] is False
assert data["decision_count"] == 3, data
assert data["counts_by_risk"]["R5"] == 1, data
assert data["counts_by_risk"]["R4"] == 1, data
assert data["counts_by_risk"]["R0"] == 1, data
assert data["policy_candidate_count"] == 0, data
assert data["items"][0]["risk"] == "R5", data["items"]
assert data["items"][0]["title"] == "Approve privacy policy boundary", data["items"][0]
assert data["items"][0]["required_skills"] == {"privacy": "L5"}, data["items"][0]
assert data["items"][0]["coverage_status"] == "missing_skill", data["items"][0]
open_items = [item for item in data["items"] if item["source"] == "open_decision"]
assert len(open_items) == 1, data["items"]
assert open_items[0]["decision"] == "DEC-0001", open_items[0]
assert open_items[0]["coverage_status"] == "human_record_required", open_items[0]
assert data["recommended_order"][0]["risk"] == "R5", data["recommended_order"]
PY

# Recommendation outside the option range is rejected.
if ./bin/palari decide create DEC-0002 "Bad rec" --option a --option b --recommend 3 >/dev/null 2>&1; then
	fail "out-of-range --recommend should be rejected"
fi

# Open decisions appear in the snapshot.
./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
grep -Fq '"open_decisions":[{"id":"DEC-0001"' "$TMP_ROOT/snapshot.json" ||
	fail "snapshot missing open decision"

# decide lint passes on the well-formed decision.
./bin/palari decide lint >/dev/null || fail "decide lint should pass"

# Recording requires a human (--by) and a valid choice.
if ./bin/palari decide record DEC-0001 --choice 1 >/dev/null 2>&1; then
	fail "decide record without --by should be rejected"
fi
if ./bin/palari decide record DEC-0001 --choice 9 --by founder >/dev/null 2>&1; then
	fail "decide record with an invalid choice should be rejected"
fi
./bin/palari decide record DEC-0001 --choice 2 --by founder --note "Multi-user matters" >"$TMP_ROOT/record.out"
[[ -f decisions/decided/DEC-0001-pick-storage-backend.md ]] ||
	fail "recorded decision not moved to decisions/decided"
grep -Fq "chosen_option: 2" decisions/decided/DEC-0001-*.md ||
	fail "recorded decision missing chosen_option"
grep -Fq "Chosen: Option 2" decisions/decided/DEC-0001-*.md ||
	fail "recorded decision missing outcome section"
[[ -f memory/decisions/DEC-0001-pick-storage-backend.md ]] ||
	fail "recorded decision not mirrored into repo memory"

# Recorded decisions cannot be recorded twice.
if ./bin/palari decide record DEC-0001 --choice 1 --by founder >/dev/null 2>&1; then
	fail "an already-decided decision should not be recordable again"
fi

# Snapshot no longer lists it as open.
./bin/palari snapshot --json >"$TMP_ROOT/snapshot2.json"
grep -Fq '"open_decisions":[]' "$TMP_ROOT/snapshot2.json" ||
	fail "snapshot should show no open decisions after recording"

printf 'decisions: ok\n'
