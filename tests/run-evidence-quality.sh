#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'evidence-quality: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-evidence-quality.sh
rm -f tickets/open/*.md tickets/open/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "evidence@example.invalid"
git config user.name "Evidence Test"
git add .
git commit -m "evidence baseline" >/dev/null

./bin/palari ticket create EVD-0001 "Evidence scoring sample" \
	--risk R2 \
	--priority P1 \
	--allowed README.md \
	--allowed tickets/open/EVD-0001-*.md \
	--allowed tickets/closed/EVD-0001-*.md \
	--allowed reports/EVD-0001-technical-report.md \
	--allowed reports/EVD-0001-reviewer-note.md \
	--allowed reports/evidence/EVD-0001/** \
	--verify "test -f README.md" \
	--review \
	--contract >/dev/null

./bin/palari evidence score EVD-0001 >"$TMP_ROOT/missing.out"
grep -Fq "rating: needs-evidence" "$TMP_ROOT/missing.out" ||
	fail "missing evidence should be rated needs-evidence"
grep -Fq "missing +0  reports/evidence/EVD-0001/manifest.json" "$TMP_ROOT/missing.out" ||
	fail "missing manifest diagnostic not shown"
if ./bin/palari evidence score EVD-0001 --strict >"$TMP_ROOT/strict-missing.out" 2>&1; then
	fail "strict scoring should fail before evidence is complete"
fi

./bin/palari ticket claim EVD-0001 tester --allow-overlap >/dev/null

cat >reports/EVD-0001-technical-report.md <<'DOC'
# EVD-0001 Technical Report

## Files Changed

- `README.md`

## Verification

- `test -f README.md`

## CI Evidence

- `reports/evidence/EVD-0001/`

## Risks / Follow-Ups

- None.
DOC

cat >reports/EVD-0001-reviewer-note.md <<'DOC'
# EVD-0001 Reviewer Note

## Review Result

Ready for acceptance.

## Findings

No blocking findings.

## Verification Reviewed

- `test -f README.md`

## Required Changes

None.

## Recommendation

Accept after human review if desired.
DOC

./bin/palari ci EVD-0001 >/dev/null
./bin/palari ticket ready EVD-0001 >/dev/null

./bin/palari evidence score EVD-0001 >"$TMP_ROOT/complete.out"
grep -Fq "score: 100/100" "$TMP_ROOT/complete.out" ||
	fail "complete evidence should score 100"
grep -Fq "rating: ready" "$TMP_ROOT/complete.out" ||
	fail "complete evidence should be ready"
grep -Fq "next_action: human gate: ./bin/palari accept EVD-0001 --by HUMAN" "$TMP_ROOT/complete.out" ||
	fail "ready in-review ticket should point to human accept command"
./bin/palari evidence score EVD-0001 --strict >/dev/null
git add .
git commit -m "evidence fixture one" >/dev/null

./bin/palari ticket create EVD-0002 "Skipped process evidence" \
	--risk R1 \
	--priority P1 \
	--allowed README.md \
	--allowed tickets/open/EVD-0002-*.md \
	--allowed tickets/closed/EVD-0002-*.md \
	--allowed reports/EVD-0002-technical-report.md \
	--allowed reports/evidence/EVD-0002/** \
	--verify "manual verify the acceptance criteria by reading README.md" >/dev/null

./bin/palari ticket claim EVD-0002 implementer --allow-overlap >/dev/null

cat >reports/EVD-0002-technical-report.md <<'DOC'
# EVD-0002 Technical Report

## Files Changed

- `README.md`

## Verification

- `manual verify the acceptance criteria by reading README.md`

## CI Evidence

- `reports/evidence/EVD-0002/`

## Risks / Follow-Ups

- This fixture should not be accept-ready because its own verification is skipped.
DOC

./bin/palari ci EVD-0002 >/dev/null
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("reports/evidence/EVD-0002/manifest.json").read_text(encoding="utf-8"))
assert data["skipped"] == 1, data
assert data["skipped_acceptance_criteria"] is True, data
assert data["skipped_checks"][0]["acceptance_criteria"] is True, data
assert "manual verify" in data["skipped_checks"][0]["reason"], data
PY
./bin/palari ticket ready EVD-0002 >/dev/null
if ./bin/palari evidence score EVD-0002 --strict >"$TMP_ROOT/skipped-strict.out" 2>&1; then
	fail "strict scoring should fail when own-ticket verification is skipped"
fi
grep -Fq "skipped verification covers acceptance criteria" "$TMP_ROOT/skipped-strict.out" ||
	fail "skipped acceptance-criteria diagnostic not shown"
if ./bin/palari accept EVD-0002 --by reviewer >"$TMP_ROOT/skipped-accept.out" 2>&1; then
	fail "accept should fail when own-ticket verification is skipped"
fi
grep -Fq "skipped verification covers acceptance criteria" "$TMP_ROOT/skipped-accept.out" ||
	fail "accept skipped diagnostic not shown"
python3 - <<'PY'
import json
from pathlib import Path

path = Path("reports/evidence/EVD-0002/manifest.json")
data = json.loads(path.read_text(encoding="utf-8"))
data["skipped_acceptance_criteria"] = False
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
if ./bin/palari evidence score EVD-0002 --strict >"$TMP_ROOT/tampered-strict.out" 2>&1; then
	fail "strict scoring should fail when skip manifest flags are inconsistent"
fi
grep -Fq "skipped_acceptance_criteria is inconsistent with skipped_checks" "$TMP_ROOT/tampered-strict.out" ||
	fail "tampered skipped-acceptance diagnostic not shown"
if ./bin/palari accept EVD-0002 --by reviewer >"$TMP_ROOT/tampered-accept.out" 2>&1; then
	fail "accept should fail when skip manifest flags are inconsistent"
fi
grep -Fq "skipped_acceptance_criteria is inconsistent with skipped_checks" "$TMP_ROOT/tampered-accept.out" ||
	fail "accept tampered skipped-acceptance diagnostic not shown"
git add .
git commit -m "skipped evidence fixture" >/dev/null

./bin/palari ticket create EVD-0003 "Docs skip exception" \
	--stream docs \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--allowed tickets/open/EVD-0003-*.md \
	--allowed reports/EVD-0003-technical-report.md \
	--allowed reports/evidence/EVD-0003/** \
	--verify "manual documentation review for expected-failure notes" >/dev/null

python3 - <<'PY'
from pathlib import Path

path = Path("tickets/open/EVD-0003-docs-skip-exception.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "requires_human_confirmation:",
    "evidence_skip_exception: documentation\n"
    "evidence_followup_tickets:\n"
    "  - EVD-0099\n"
    "requires_human_confirmation:",
    1,
)
path.write_text(text, encoding="utf-8")
PY
./bin/palari ticket claim EVD-0003 implementer --allow-overlap >/dev/null

cat >reports/EVD-0003-technical-report.md <<'DOC'
# EVD-0003 Technical Report

## Files Changed

- `README.md`

## Verification

- `manual documentation review for expected-failure notes`

## CI Evidence

- `reports/evidence/EVD-0003/`

## Risks / Follow-Ups

- This fixture is explicitly documentation work, so skipped manual evidence may be ready but must remain visible.
DOC

./bin/palari ci EVD-0003 >/dev/null
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("reports/evidence/EVD-0003/manifest.json").read_text(encoding="utf-8"))
assert data["skipped"] == 1, data
assert data["expected_failures"] == 1, data
assert data["follow_up_tickets"] == ["EVD-0099"], data
assert data["skipped_acceptance_criteria"] is True, data
PY
./bin/palari ticket ready EVD-0003 >/dev/null
./bin/palari evidence score EVD-0003 --strict >"$TMP_ROOT/docs-strict.out"
grep -Fq "truthfulness: skipped=1 skipped_acceptance_criteria=true skipped_checks=1 expected_failures=1 fixme_count=0 follow_up_tickets=EVD-0099" "$TMP_ROOT/docs-strict.out" ||
	fail "allowed docs skip truthfulness summary not shown"
git add .
git commit -m "docs skip exception fixture" >/dev/null

./bin/palari ticket create EVD-0004 "Output-only deferred evidence" \
	--risk R1 \
	--priority P2 \
	--allowed tickets/open/EVD-0004-*.md \
	--allowed reports/EVD-0004-technical-report.md \
	--allowed reports/EVD-0004-emit-marker.sh \
	--allowed reports/evidence/EVD-0004/** \
	--verify "bash reports/EVD-0004-emit-marker.sh" >/dev/null

./bin/palari ticket claim EVD-0004 implementer --allow-overlap >/dev/null
cat >reports/EVD-0004-emit-marker.sh <<'SH'
#!/usr/bin/env bash
printf 'TODO-output-marker\n'
SH
cat >reports/EVD-0004-technical-report.md <<'DOC'
# EVD-0004 Technical Report

## Files Changed

- `tickets/open/EVD-0004-output-only-deferred-evidence.md`
- `reports/EVD-0004-emit-marker.sh`

## Verification

- output-only deferred marker fixture

## CI Evidence

- `reports/evidence/EVD-0004/`

## Risks / Follow-Ups

- This fixture should not be accept-ready because command output contains deferred evidence without a follow-up.
DOC

./bin/palari ci EVD-0004 >/dev/null
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("reports/evidence/EVD-0004/manifest.json").read_text(encoding="utf-8"))
assert data["fixme_count"] == 1, data
assert data["expected_failures"] == 0, data
PY
./bin/palari ticket ready EVD-0004 >/dev/null
if ./bin/palari evidence score EVD-0004 --strict >"$TMP_ROOT/output-deferred-strict.out" 2>&1; then
	fail "strict scoring should fail when command output contains deferred evidence without follow-up"
fi
grep -Fq "expected-failure or fixme evidence requires evidence_followup_tickets" "$TMP_ROOT/output-deferred-strict.out" ||
	fail "output-only deferred evidence diagnostic not shown"

printf 'evidence-quality: ok\n'
