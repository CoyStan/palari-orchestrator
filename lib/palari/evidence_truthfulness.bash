# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash, which defines shared globals.

evidence_truth_init() {
	local out_dir="$1"
	CI_SKIPPED_CHECKS_FILE="$out_dir/.skipped-checks.tmp"
	CI_FOLLOW_UP_TICKETS_FILE="$out_dir/.follow-up-tickets.tmp"
	CI_EXPECTED_FAILURES=0
	CI_FIXME_COUNT=0
	CI_SKIPPED_ACCEPTANCE_CRITERIA="false"
	: >"$CI_SKIPPED_CHECKS_FILE"
	: >"$CI_FOLLOW_UP_TICKETS_FILE"
}

evidence_truth_cleanup() {
	rm -f "${CI_SKIPPED_CHECKS_FILE:-}" "${CI_FOLLOW_UP_TICKETS_FILE:-}"
}

evidence_truth_scan_text() {
	local text="${1,,}"
	[[ "$text" == *fixme* || "$text" == *todo* ]] && CI_FIXME_COUNT=$((CI_FIXME_COUNT + 1))
	[[ "$text" == *"expected failure"* || "$text" == *"expected-failure"* || "$text" == *xfail* ]] && CI_EXPECTED_FAILURES=$((CI_EXPECTED_FAILURES + 1))
	return 0
}

evidence_truth_note_skip() {
	local name="$1"
	local reason="${2:-}"
	CI_SKIPPED_ACCEPTANCE_CRITERIA="true"
	[[ -n "${CI_SKIPPED_CHECKS_FILE:-}" ]] || return 0
	printf '%s\t%s\n' "$name" "$reason" >>"$CI_SKIPPED_CHECKS_FILE"
	return 0
}

evidence_truth_note_followups() {
	local file="$1" item
	[[ -n "${CI_FOLLOW_UP_TICKETS_FILE:-}" ]] || return 0
	while IFS= read -r item; do
		[[ -n "$item" ]] && printf '%s\n' "$item" >>"$CI_FOLLOW_UP_TICKETS_FILE"
	done < <(frontmatter_list_items "$file" evidence_followup_tickets)
	return 0
}

evidence_truth_json_string_array_file() {
	local file="$1" item first="true"
	printf '['
	[[ -s "$file" ]] || {
		printf ']'
		return 0
	}
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		json_string "$item"
		first="false"
	done < <(sort -u "$file")
	printf ']'
}

evidence_truth_json_skipped_checks() {
	local file="$1" name reason first="true"
	printf '['
	[[ -s "$file" ]] || {
		printf ']'
		return 0
	}
	while IFS=$'\t' read -r name reason; do
		[[ -n "$name" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		printf '{"name":'
		json_string "$name"
		printf ',"reason":'
		json_string "$reason"
		printf ',"acceptance_criteria":true}'
		first="false"
	done <"$file"
	printf ']'
}

evidence_truth_manifest_fields() {
	printf ',\n  "expected_failures": %s,\n  "fixme_count": %s,\n  "skipped_acceptance_criteria": %s,\n  "skipped_checks": ' \
		"${CI_EXPECTED_FAILURES:-0}" "${CI_FIXME_COUNT:-0}" "${CI_SKIPPED_ACCEPTANCE_CRITERIA:-false}"
	evidence_truth_json_skipped_checks "${CI_SKIPPED_CHECKS_FILE:-/dev/null}"
	printf ',\n  "follow_up_tickets": '
	evidence_truth_json_string_array_file "${CI_FOLLOW_UP_TICKETS_FILE:-/dev/null}"
}

evidence_truth_ticket_allows_skipped_acceptance() {
	local file="$1" exception stream
	[[ -n "$file" && -f "$file" ]] || return 1
	exception="$(frontmatter_value "$file" evidence_skip_exception)"
	stream="$(frontmatter_value "$file" stream)"
	case "$exception" in
	documentation | test-discovery | discovery) return 0 ;;
	esac
	case "$stream" in
	docs | documentation | test-discovery) return 0 ;;
	esac
	return 1
}

evidence_truth_validate_manifest() {
	local ticket_id="$1"
	local manifest="$2"
	local prefix="$3"
	local file allow_skips="false"
	file="$(find_ticket_file "$ticket_id" || true)"
	evidence_truth_ticket_allows_skipped_acceptance "$file" && allow_skips="true"
	python3 - "$manifest" "$ticket_id" "$prefix" "$allow_skips" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
ticket_id = sys.argv[2]
prefix = sys.argv[3]
allow_skips = sys.argv[4] == "true"


def fail(message: str) -> None:
    print(f"{prefix} for {ticket_id}: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"cannot parse truthfulness metadata: {exc}")

for key in ("skipped", "expected_failures", "fixme_count"):
    value = data.get(key, 0)
    if not isinstance(value, int) or value < 0:
        fail(f"{key} must be a non-negative integer")

skipped_count = data.get("skipped", 0)
skipped_acceptance = data.get("skipped_acceptance_criteria", skipped_count > 0)
if not isinstance(skipped_acceptance, bool):
    fail("skipped_acceptance_criteria must be a boolean")

skipped_checks = data.get("skipped_checks", [])
if not isinstance(skipped_checks, list):
    fail("skipped_checks must be a list")
skipped_checks_acceptance = False
for item in skipped_checks:
    if not isinstance(item, dict):
        fail("skipped_checks entries must be objects")
    if not isinstance(item.get("name"), str) or not item.get("name"):
        fail("skipped_checks entries must include a name")
    if not isinstance(item.get("reason", ""), str):
        fail("skipped_checks reason must be a string")
    if item.get("acceptance_criteria") is not True:
        fail("skipped_checks entries must state acceptance_criteria: true")
    skipped_checks_acceptance = True
if skipped_count > 0 and not skipped_checks:
    fail("skipped_checks must describe skipped verification")
if skipped_count != len(skipped_checks):
    fail("skipped count is inconsistent with skipped_checks")
derived_skipped_acceptance = skipped_checks_acceptance
if skipped_acceptance != derived_skipped_acceptance:
    fail("skipped_acceptance_criteria is inconsistent with skipped_checks")

followups = data.get("follow_up_tickets", [])
if not isinstance(followups, list) or not all(isinstance(item, str) and item for item in followups):
    fail("follow_up_tickets must be a list of ticket IDs")

deferred = data.get("expected_failures", 0) > 0 or data.get("fixme_count", 0) > 0
if derived_skipped_acceptance and not allow_skips:
    fail("skipped verification covers acceptance criteria; add evidence_skip_exception: documentation or test-discovery only for explicit discovery/documentation work")
if deferred and not (allow_skips or followups):
    fail("expected-failure or fixme evidence requires evidence_followup_tickets or an explicit documentation/test-discovery exception")
PY
}
