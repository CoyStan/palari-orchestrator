#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
	printf 'retrospective-governance: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-retrospective-governance.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari

git init -b main >/dev/null
git config user.email "retrospective@example.invalid"
git config user.name "Retrospective Test"
./bin/palari init --ci --hooks >/dev/null
git add .
git commit -m "retrospective governance baseline" >/dev/null

set_retrospective_fields() {
	local file="$1"
	local commits_csv="$2"
	local reason="$3"
	python3 - "$file" "$commits_csv" "$reason" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
commits = [item for item in sys.argv[2].split(",") if item]
reason = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()
out = []
skip_commit_items = False
for line in lines:
    if line.startswith("retrospective:") or line.startswith("retrospective_bypass_reason:"):
        continue
    if line.startswith("retrospective_original_commits:"):
        skip_commit_items = True
        continue
    if skip_commit_items and line.startswith("  - "):
        continue
    skip_commit_items = False
    out.append(line)
    if line.startswith("requires_review:"):
        out.append("retrospective: true")
        if commits:
            out.append("retrospective_original_commits:")
            out.extend(f"  - {commit}" for commit in commits)
        if reason:
            out.append(f"retrospective_bypass_reason: {json.dumps(reason)}")
path.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
}

create_ticket() {
	local ticket="$1"
	local title="$2"
	local risk="${3:-R1}"
	./bin/palari ticket create "$ticket" "$title" \
		--stream process \
		--risk "$risk" \
		--allowed "contracts/retrospective-fixtures/$ticket.md" \
		--allowed "tickets/open/$ticket-*" \
		--allowed "tickets/closed/$ticket-*" \
		--allowed "reports/$ticket-*" \
		--allowed "reports/human/$ticket-*" \
		--allowed "reports/evidence/$ticket/**" \
		--verify "test -f contracts/retrospective-fixtures/$ticket.md" >/dev/null
	printf 'tickets/open/%s-' "$ticket"
}

RET1_PREFIX="$(create_ticket RET-0001 "Retrospective missing metadata")"
RET1_FILE="$(printf '%s' "$RET1_PREFIX"*.md)"
set_retrospective_fields "$RET1_FILE" "" ""
if ./bin/palari lint RET-0001 >"$TMP_ROOT/lint-missing.out" 2>&1; then
	fail "retrospective ticket without original commits should fail lint"
fi
grep -Fq "retrospective tickets must list retrospective_original_commits" "$TMP_ROOT/lint-missing.out" ||
	fail "missing original commit failure was not reported"
grep -Fq "retrospective tickets must set retrospective_bypass_reason" "$TMP_ROOT/lint-missing.out" ||
	fail "missing bypass reason failure was not reported"

set_retrospective_fields "$RET1_FILE" "abc1234,def5678" "landed before Palari governance controlled this repository"
./bin/palari lint RET-0001 >"$TMP_ROOT/lint-ret1.out"
grep -Fq "lint: ok for RET-0001" "$TMP_ROOT/lint-ret1.out" ||
	fail "valid low-risk retrospective ticket should pass lint"

./bin/palari snapshot --json >"$TMP_ROOT/fast-snapshot.json"
PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json >"$TMP_ROOT/bash-snapshot.json"
python3 - "$TMP_ROOT/fast-snapshot.json" "$TMP_ROOT/bash-snapshot.json" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    snapshot = json.load(open(path, encoding="utf-8"))
    tickets = {ticket["id"]: ticket for ticket in snapshot["tickets"]}
    ticket = tickets["RET-0001"]
    assert ticket["retrospective"] is True, path
    assert ticket["retrospective_original_commits"] == ["abc1234", "def5678"], path
    assert "before Palari governance" in ticket["retrospective_bypass_reason"], path
PY

RET2_PREFIX="$(create_ticket RET-0002 "High risk disabled retrospective gates" R3)"
RET2_FILE="$(printf '%s' "$RET2_PREFIX"*.md)"
set_retrospective_fields "$RET2_FILE" "feed123" "governance was backfilled after landing"
python3 - "$RET2_FILE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = text.replace("requires_human_confirmation: true", "requires_human_confirmation: false", 1)
text = text.replace("requires_review: true", "requires_review: false", 1)
path.write_text(text, encoding="utf-8")
PY
if ./bin/palari lint RET-0002 >"$TMP_ROOT/lint-disabled.out" 2>&1; then
	fail "high-risk retrospective ticket with disabled gates should fail lint"
fi
grep -Fq "high-risk retrospective tickets must keep requires_review: true" "$TMP_ROOT/lint-disabled.out" ||
	fail "disabled review gate failure was not reported"
grep -Fq "high-risk retrospective tickets must keep requires_human_confirmation: true" "$TMP_ROOT/lint-disabled.out" ||
	fail "disabled human gate failure was not reported"
rm -f "$RET2_FILE"

RET3_PREFIX="$(create_ticket RET-0003 "High risk retrospective report gate" R3)"
RET3_FILE="$(printf '%s' "$RET3_PREFIX"*.md)"
set_retrospective_fields "$RET3_FILE" "cafe456" "normal governance was unavailable when this landed"
./bin/palari ticket claim RET-0003 tester --allow-overlap >/dev/null
./bin/palari ticket ready RET-0003 >/dev/null
if ./bin/palari report-lint RET-0003 >"$TMP_ROOT/report-missing.out" 2>&1; then
	fail "high-risk in-review retrospective ticket without reports should fail report-lint"
fi
grep -Fq "missing technical/specialist report" "$TMP_ROOT/report-missing.out" ||
	fail "missing technical report failure was not reported"
grep -Fq "missing fresh-context reviewer note" "$TMP_ROOT/report-missing.out" ||
	fail "missing reviewer note failure was not reported"
grep -Fq "missing human/founder report" "$TMP_ROOT/report-missing.out" ||
	fail "missing human report failure was not reported"

printf 'retrospective-governance: ok\n'
