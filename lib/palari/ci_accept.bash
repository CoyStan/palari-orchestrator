# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash, which defines shared globals.
infer_ticket_from_branch() {
	local branch id
	branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
	case "$branch" in
	ticket/*)
		id="${branch#ticket/}"
		[[ -n "$id" ]] && printf '%s\n' "$id" && return 0
		;;
	esac
	return 1
}

ci_add_junit_case() {
	local name="$1"
	local state="$2"
	local body="${3:-}"
	local name_xml body_xml
	name_xml="$(printf '%s' "$name" | xml_escape)"
	body_xml="$(printf '%s' "$body" | xml_escape)"
	CI_TESTS=$((CI_TESTS + 1))
	case "$state" in
	pass)
		printf '    <testcase classname="palari" name="%s"/>\n' "$name_xml" >>"$CI_JUNIT_CASES"
		;;
	skip)
		CI_SKIPPED=$((CI_SKIPPED + 1))
		printf '    <testcase classname="palari" name="%s"><skipped message="%s"/></testcase>\n' "$name_xml" "$body_xml" >>"$CI_JUNIT_CASES"
		;;
	fail)
		CI_FAILURES=$((CI_FAILURES + 1))
		printf '    <testcase classname="palari" name="%s"><failure message="failed"><![CDATA[%s]]></failure></testcase>\n' "$name_xml" "$body" >>"$CI_JUNIT_CASES"
		;;
	esac
}

ci_add_sarif_failure() {
	local rule="$1"
	local message="$2"
	local rule_json message_json location_json
	rule_json="$(printf '%s' "$rule" | json_escape)"
	message_json="$(printf '%s' "$message" | json_escape)"
	location_json="$(printf '%s' "${CI_SARIF_LOCATION:-palari.config.yaml}" | json_escape)"
	[[ ! -s "$CI_SARIF_RESULTS" ]] || printf ',\n' >>"$CI_SARIF_RESULTS"
	printf '        {"ruleId":"%s","level":"error","message":{"text":"%s"},"locations":[{"physicalLocation":{"artifactLocation":{"uri":"%s"},"region":{"startLine":1}}}]}' \
		"$rule_json" "$message_json" "$location_json" >>"$CI_SARIF_RESULTS"
}

ci_run_step() {
	local label="$1"
	shift
	local output code
	{
		printf '\n## %s\n\n' "$label"
		printf '```text\n'
	} >>"$CI_LOG"
	set +e
	output="$("$@" 2>&1)"
	code=$?
	set -e
	printf '%s\n' "$output" >>"$CI_LOG"
	printf '```\n' >>"$CI_LOG"
	if ((code == 0)); then
		ci_add_junit_case "$label" pass
	else
		ci_add_junit_case "$label" fail "$output"
		ci_add_sarif_failure "$label" "$output"
	fi
	return "$code"
}

ci_run_shell_step() {
	local label="$1"
	local command="$2"
	local output code
	{
		printf '\n## %s\n\n' "$label"
		# shellcheck disable=SC2016 # Backticks are literal Markdown in evidence output.
		printf 'Command: `%s`\n\n' "$command"
		printf '```text\n'
	} >>"$CI_LOG"
	set +e
	output="$(bash -lc "$command" 2>&1)"
	code=$?
	set -e
	printf '%s\n' "$output" >>"$CI_LOG"
	printf '```\n' >>"$CI_LOG"
	if ((code == 0)); then
		ci_add_junit_case "$label" pass
	else
		ci_add_junit_case "$label" fail "$output"
		ci_add_sarif_failure "$label" "$output"
	fi
	return "$code"
}

ci_write_artifacts() {
	local junit="$1"
	local sarif="$2"
	{
		printf '<?xml version="1.0" encoding="UTF-8"?>\n'
		printf '<testsuite name="palari" tests="%s" failures="%s" skipped="%s">\n' "$CI_TESTS" "$CI_FAILURES" "$CI_SKIPPED"
		cat "$CI_JUNIT_CASES"
		printf '</testsuite>\n'
	} >"$junit"
	{
		printf '{\n'
		# shellcheck disable=SC2016 # JSON requires a literal "$schema" key.
		printf '  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",\n'
		printf '  "version": "2.1.0",\n'
		printf '  "runs": [\n'
		printf '    {\n'
		printf '      "tool": {"driver": {"name": "palari-ci", "informationUri": "https://github.com/CoyStan/palari-orchestrator"}},\n'
		printf '      "automationDetails": {"id": "%s"},\n' "$(printf '%s' "${CI_SARIF_RUN_ID:-palari/repo}" | json_escape)"
		printf '      "results": [\n'
		cat "$CI_SARIF_RESULTS"
		printf '\n      ]\n'
		printf '    }\n'
		printf '  ]\n'
		printf '}\n'
	} >"$sarif"
}

ci_write_manifest() {
	local manifest="$1"
	local ticket_label="$2"
	local base_ref="$3"
	local failed="$4"
	local log="$5"
	local junit="$6"
	local sarif="$7"
	local head_sha status
	head_sha="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
	[[ "$failed" == "0" && "$CI_FAILURES" == "0" ]] && status="passed" || status="failed"
	{
		printf '{\n'
		printf '  "schema_version": "1",\n'
		printf '  "generator": "palari-ci",\n'
		printf '  "manifest_file": "manifest.json",\n'
		printf '  "ticket": '
		json_string "$ticket_label"
		printf ',\n  "base_ref": '
		json_string "${base_ref:-local working tree}"
		printf ',\n  "head_sha": '
		json_string "$head_sha"
		printf ',\n  "created_at": '
		json_string "$(now_utc)"
		printf ',\n  "status": '
		json_string "$status"
		printf ',\n  "tests": %s,\n  "failures": %s,\n  "skipped": %s,\n' "$CI_TESTS" "$CI_FAILURES" "$CI_SKIPPED"
		printf '  "artifacts": [\n'
		printf '    {"name":"verification.log","sha256":'
		json_string "$(sha256_file "$log")"
		printf '},\n'
		printf '    {"name":"junit.xml","sha256":'
		json_string "$(sha256_file "$junit")"
		printf '},\n'
		printf '    {"name":"palari.sarif","sha256":'
		json_string "$(sha256_file "$sarif")"
		printf '}\n'
		printf '  ]\n'
		printf '}\n'
	} >"$manifest"
}

ci_existing_evidence_valid() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local manifest="$dir/manifest.json"
	[[ -s "$manifest" ]] || {
		printf 'ci: evidence manifest missing or empty for %s: %s/manifest.json\n' "$ticket_id" "$EVIDENCE_DIR/$ticket_id" >&2
		return 1
	}
	command -v python3 >/dev/null 2>&1 || {
		printf 'ci: python3 required to validate evidence manifest for %s\n' "$ticket_id" >&2
		return 1
	}

	python3 - "$manifest" "$dir" "$ticket_id" <<'PY'
import hashlib
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
evidence_dir = pathlib.Path(sys.argv[2])
ticket_id = sys.argv[3]
required = {"verification.log", "junit.xml", "palari.sarif"}


def fail(message: str) -> None:
    print(f"ci: invalid evidence manifest for {ticket_id}: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"cannot parse manifest.json: {exc}")

checks = {
    "schema_version": "1",
    "generator": "palari-ci",
    "ticket": ticket_id,
    "status": "passed",
}
for key, expected in checks.items():
    actual = data.get(key)
    if actual != expected:
        fail(f"{key} is {actual!r}, expected {expected!r}")

artifacts = data.get("artifacts")
if not isinstance(artifacts, list):
    fail("artifacts must be a list with sha256 entries")

seen = set()
root = evidence_dir.resolve()
for item in artifacts:
    if not isinstance(item, dict):
        fail("artifact entry must be an object")
    name = item.get("name")
    digest = item.get("sha256")
    if name not in required:
        continue
    if not isinstance(digest, str) or len(digest) != 64:
        fail(f"{name} has missing or invalid sha256")
    path = (evidence_dir / name).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        fail(f"{name} escapes evidence directory")
    if not path.is_file() or path.stat().st_size == 0:
        fail(f"{name} is missing or empty")
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != digest:
        fail(f"{name} sha256 mismatch")
    seen.add(name)

missing = required - seen
if missing:
    fail("missing artifact hash entries: " + ", ".join(sorted(missing)))
PY
}

ci_use_existing_evidence() {
	local ticket_id="$1"
	ci_existing_evidence_valid "$ticket_id" || return 1
	ci_record_existing_evidence "$ticket_id"
	return 0
}

ci_record_existing_evidence() {
	local ticket_id="$1"
	ci_add_junit_case "stored evidence $ticket_id" pass
	{
		printf '\n## stored evidence %s\n\n' "$ticket_id"
		printf 'Reused accepted ticket evidence from `%s/%s`.\n' "$EVIDENCE_DIR" "$ticket_id"
	} >>"$CI_LOG"
	return 0
}

cmd_ci() {
	require_base_folders
	local ticket="" base_ref="" evidence_dir="$EVIDENCE_DIR" repo_only="false" arg
	local -a tickets=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--base)
			base_ref="$2"
			shift 2
			;;
		--evidence-dir)
			evidence_dir="$2"
			shift 2
			;;
		--ticket)
			tickets+=("$2")
			shift 2
			;;
		--repo-only)
			repo_only="true"
			shift
			;;
		--*) die "unknown ci option: $arg" ;;
		*)
			tickets+=("$arg")
			shift
			;;
		esac
	done
	if ((${#tickets[@]} == 0)) && [[ -n "${PALARI_TICKET_ID:-}" ]]; then
		tickets+=("$PALARI_TICKET_ID")
	fi
	if ((${#tickets[@]} == 0)); then
		ticket="$(infer_ticket_from_branch || true)"
		[[ -n "$ticket" ]] && tickets+=("$ticket")
	fi
	if ((${#tickets[@]} == 0)) && [[ "$repo_only" != "true" ]]; then
		die "ci requires a ticket ID, a ticket/* branch, or PALARI_TICKET_ID; use --repo-only only for non-merge-gate repository checks"
	fi

	local ticket_label="repo"
	if ((${#tickets[@]} == 1)); then
		ticket_label="${tickets[0]}"
	elif ((${#tickets[@]} > 1)); then
		ticket_label="$(
			IFS=+
			printf '%s' "${tickets[*]}"
		)"
		if ((${#ticket_label} > 120)); then
			local ticket_hash
			ticket_hash="$(printf '%s' "$ticket_label" | sha256_text | cut -c1-16)"
			ticket_label="bundle-${#tickets[@]}-$ticket_hash"
		fi
	fi
	local reuse_single_evidence="false" single_ticket_file=""
	if ((${#tickets[@]} == 1)); then
		single_ticket_file="$(find_ticket_file "${tickets[0]}" || true)"
		if [[ -n "$single_ticket_file" ]] &&
			[[ "$(frontmatter_value "$single_ticket_file" status)" == "accepted" ]] &&
			ci_existing_evidence_valid "${tickets[0]}"; then
			reuse_single_evidence="true"
		fi
	fi
	local out_dir="$ROOT/$evidence_dir/$ticket_label"
	local log="$out_dir/verification.log"
	local junit="$out_dir/junit.xml"
	local sarif="$out_dir/palari.sarif"
	local manifest="$out_dir/manifest.json"
	mkdir -p "$out_dir"
	CI_LOG="$log"
	CI_JUNIT_CASES="$out_dir/.junit-cases.tmp"
	CI_SARIF_RESULTS="$out_dir/.sarif-results.tmp"
	CI_TESTS=0
	CI_FAILURES=0
	CI_SKIPPED=0
	CI_SARIF_RUN_ID="palari/$ticket_label"
	CI_SARIF_LOCATION="palari.config.yaml"
	: >"$CI_JUNIT_CASES"
	: >"$CI_SARIF_RESULTS"
	{
		printf '# Palari CI Evidence\n\n'
		printf -- '- Ticket: %s\n' "$ticket_label"
		printf -- '- Base ref: %s\n' "${base_ref:-local working tree}"
		printf -- '- Created: %s\n' "$(now_utc)"
	} >"$log"

	local failed=0 file check index=0 current_ticket
	if ((${#tickets[@]} == 1)); then
		current_ticket="${tickets[0]}"
		file="$single_ticket_file"
		[[ -n "$file" ]] || file="$(find_ticket_file "$current_ticket")" || die "ticket not found: $current_ticket"
		CI_SARIF_LOCATION="${file#"$ROOT"/}"
		if [[ -n "$base_ref" ]]; then
			ci_run_step "scope-check" cmd_scope_check "$current_ticket" --base "$base_ref" || failed=1
		else
			ci_run_step "scope-check" cmd_scope_check "$current_ticket" || failed=1
		fi
		ci_run_step "lint" cmd_lint "$current_ticket" || failed=1
		if [[ "$reuse_single_evidence" == "true" ]]; then
			ci_record_existing_evidence "$current_ticket"
			ci_write_artifacts "$junit" "$sarif"
			ci_write_manifest "$manifest" "$ticket_label" "$base_ref" "$failed" "$log" "$junit" "$sarif"
			rm -f "$CI_JUNIT_CASES" "$CI_SARIF_RESULTS"
			printf 'ci evidence: %s\n' "${out_dir#"$ROOT"/}"
			printf 'ci junit: %s\n' "${junit#"$ROOT"/}"
			printf 'ci sarif: %s\n' "${sarif#"$ROOT"/}"
			printf 'ci manifest: %s\n' "${manifest#"$ROOT"/}"
			if ((failed != 0 || CI_FAILURES != 0)); then
				printf 'ci: failed for %s\n' "$ticket_label" >&2
				exit 1
			fi
			printf 'ci: ok for %s\n' "$ticket_label"
			return
		fi
		while IFS= read -r check; do
			[[ -n "$check" ]] || continue
			index=$((index + 1))
			case "$check" in
			manual* | Manual* | describe\ * | Describe\ *)
				ci_add_junit_case "verification $index" skip "manual or descriptive check: $check"
				# shellcheck disable=SC2016 # Backticks are literal Markdown in evidence output.
				printf '\n## verification %s\n\nSkipped manual/descriptive check: `%s`\n' "$index" "$check" >>"$log"
				;;
			*)
				ci_run_shell_step "verification $index" "$check" || failed=1
				;;
			esac
		done < <(frontmatter_list_items "$file" verification)
	elif ((${#tickets[@]} > 1)); then
		CI_SARIF_LOCATION="palari.config.yaml"
		ci_run_step "scope-check" scope_check_ticket_set "$base_ref" "${tickets[@]}" || failed=1
		for current_ticket in "${tickets[@]}"; do
			file="$(find_ticket_file "$current_ticket")" || die "ticket not found: $current_ticket"
			ci_run_step "lint $current_ticket" cmd_lint "$current_ticket" || failed=1
			if [[ "$(frontmatter_value "$file" status)" == "accepted" ]] && ci_use_existing_evidence "$current_ticket"; then
				continue
			fi
			index=0
			while IFS= read -r check; do
				[[ -n "$check" ]] || continue
				index=$((index + 1))
				case "$check" in
				manual* | Manual* | describe\ * | Describe\ *)
					ci_add_junit_case "$current_ticket verification $index" skip "manual or descriptive check: $check"
					# shellcheck disable=SC2016 # Backticks are literal Markdown in evidence output.
					printf '\n## %s verification %s\n\nSkipped manual/descriptive check: `%s`\n' "$current_ticket" "$index" "$check" >>"$log"
					;;
				*)
					ci_run_shell_step "$current_ticket verification $index" "$check" || failed=1
					;;
				esac
			done < <(frontmatter_list_items "$file" verification)
		done
	else
		ci_run_step "lint" cmd_lint || failed=1
	fi

	ci_write_artifacts "$junit" "$sarif"
	ci_write_manifest "$manifest" "$ticket_label" "$base_ref" "$failed" "$log" "$junit" "$sarif"
	rm -f "$CI_JUNIT_CASES" "$CI_SARIF_RESULTS"
	printf 'ci evidence: %s\n' "${out_dir#"$ROOT"/}"
	printf 'ci junit: %s\n' "${junit#"$ROOT"/}"
	printf 'ci sarif: %s\n' "${sarif#"$ROOT"/}"
	printf 'ci manifest: %s\n' "${manifest#"$ROOT"/}"
	if ((failed != 0 || CI_FAILURES != 0)); then
		printf 'ci: failed for %s\n' "$ticket_label" >&2
		exit 1
	fi
	printf 'ci: ok for %s\n' "$ticket_label"
	if ((${#tickets[@]} == 1)); then
		gate_ci_attest_test "${tickets[0]}"
	fi
}

ticket_evidence_complete() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local missing=0 name
	for name in verification.log junit.xml palari.sarif manifest.json; do
		if [[ ! -s "$dir/$name" ]]; then
			printf 'accept refused: missing evidence artifact for %s: %s/%s\n' "$ticket_id" "$EVIDENCE_DIR/$ticket_id" "$name" >&2
			missing=$((missing + 1))
		fi
	done
	return "$missing"
}

ticket_evidence_manifest_valid() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local manifest="$dir/manifest.json"
	local expected_head=""

	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		expected_head="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
	fi
	command -v python3 >/dev/null 2>&1 || die "accept requires python3 to validate evidence manifest integrity"

	python3 - "$manifest" "$dir" "$ticket_id" "$expected_head" <<'PY'
import hashlib
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
evidence_dir = pathlib.Path(sys.argv[2])
ticket_id = sys.argv[3]
expected_head = sys.argv[4]
required = {"verification.log", "junit.xml", "palari.sarif"}


def fail(message: str) -> None:
    print(f"accept refused: invalid evidence manifest for {ticket_id}: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"cannot parse manifest.json: {exc}")

checks = {
    "schema_version": "1",
    "generator": "palari-ci",
    "ticket": ticket_id,
    "status": "passed",
}
for key, expected in checks.items():
    actual = data.get(key)
    if actual != expected:
        fail(f"{key} is {actual!r}, expected {expected!r}")

if expected_head and data.get("head_sha") != expected_head:
    fail(f"head_sha is {data.get('head_sha')!r}, expected current HEAD {expected_head!r}")

artifacts = data.get("artifacts")
if not isinstance(artifacts, list):
    fail("artifacts must be a list with sha256 entries")

seen = set()
root = evidence_dir.resolve()
for item in artifacts:
    if not isinstance(item, dict):
        fail("artifact entry must be an object")
    name = item.get("name")
    digest = item.get("sha256")
    if name not in required:
        continue
    if not isinstance(digest, str) or len(digest) != 64:
        fail(f"{name} has missing or invalid sha256")
    path = (evidence_dir / name).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        fail(f"{name} escapes evidence directory")
    if not path.is_file() or path.stat().st_size == 0:
        fail(f"{name} is missing or empty")
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != digest:
        fail(f"{name} sha256 mismatch")
    seen.add(name)

missing = required - seen
if missing:
    fail("missing artifact hash entries: " + ", ".join(sorted(missing)))
PY
}

same_actor() {
	local left="${1:-}"
	local right="${2:-}"
	[[ -n "$left" && -n "$right" ]] || return 1
	[[ "${left,,}" == "${right,,}" ]]
}

accept_r5_dual_human_enforcement_enabled() {
	[[ "$(cfg_nested governance r5_requires_dual_human false)" == "true" ]]
}

accept_enforces_r5_dual_human() {
	accept_r5_dual_human_enforcement_enabled
}

accept_command_for_ticket() {
	local file="$1"
	local ticket_id="$2"
	local by="${3:-HUMAN}"
	local prefix="${4:-./bin/palari}"
	local risk
	risk="$(frontmatter_value "$file" risk)"
	if [[ "$risk" == "R5" ]] && accept_r5_dual_human_enforcement_enabled; then
		printf '%s accept %s --by HUMAN-ONE --co-by HUMAN-TWO\n' "$prefix" "$ticket_id"
	else
		printf '%s accept %s --by %s\n' "$prefix" "$ticket_id" "$by"
	fi
}

accept_ensure_frontmatter_key() {
	local file="$1" key="$2"
	frontmatter_has_key "$file" "$key" && return 0
	local tmp="${file}.tmp.$$"
	awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && $0 == "---" {
      print key ":"
      in_fm = 0
      print
      next
    }
    { print }
  ' "$file" >"$tmp"
	mv "$tmp" "$file"
}

accept_require_r5_human() {
	local actor="$1"
	local ticket_id="$2"
	local human_file risk may_policy
	human_file="$(find_human_file "$actor" active)" ||
		die "accept refused: R5 acceptor $actor must be an active human profile"
	risk="$(frontmatter_value "$human_file" authority_max_risk)"
	may_policy="$(frontmatter_value "$human_file" may_approve_policy_changes)"
	[[ "$risk" == "R5" ]] ||
		die "accept refused: R5 acceptor $actor has authority_max_risk ${risk:-missing}; R5 required for $ticket_id"
	[[ "$may_policy" == "true" ]] ||
		die "accept refused: R5 acceptor $actor must have may_approve_policy_changes: true"
}

accept_require_r5_dual_human() {
	local ticket_id="$1" by="$2" co_by="$3" claimed_by="$4" implemented_by="$5"
	[[ -n "$by" ]] || die "accept requires --by NAME; acceptance must name the human or authorized reviewer"
	[[ -n "$co_by" ]] || die "accept refused: R5 tickets require --co-by HUMAN when r5_requires_dual_human is true"
	! same_actor "$by" "$co_by" ||
		die "accept refused: R5 dual-human acceptance requires two distinct humans"
	for actor in "$by" "$co_by"; do
		if same_actor "$actor" "$claimed_by" || same_actor "$actor" "$implemented_by"; then
			die "accept refused: R5 acceptor $actor must not be the claimant or implementer for $ticket_id"
		fi
		accept_require_r5_human "$actor" "$ticket_id"
	done
}

cmd_accept() {
	require_base_folders
	local ticket="${1:-}"
	shift || true
	local by="" co_by=""
	while (($# > 0)); do
		case "$1" in
		--by)
			by="$2"
			shift 2
			;;
		--co-by)
			co_by="$2"
			shift 2
			;;
		*) die "unknown accept option: $1" ;;
		esac
	done
	[[ -n "$ticket" ]] || die "accept requires ticket ID"
	[[ -n "$by" ]] || die "accept requires --by NAME; acceptance must name the human or authorized reviewer"
	local file status id risk dest claim_ref claimed_by implemented_by self_policy r5_dual_required="false"
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	status="$(frontmatter_value "$file" status)"
	id="$(frontmatter_value "$file" id)"
	risk="$(frontmatter_value "$file" risk)"
	[[ -n "$id" ]] || id="$ticket"
	[[ "${file#"$ROOT"/}" == "$OPEN_DIR/"* ]] || die "ticket is already closed: $ticket"
	[[ "$status" == "in-review" ]] || die "accept requires in-review status; current: ${status:-missing}"
	claim_ref="$(frontmatter_value "$file" claim_ref)"
	if [[ -n "$claim_ref" || -n "$(frontmatter_value "$file" claim_expires_at)" ]]; then
		ticket_claim_expired "$file" && die "accept refused: claim lease is expired for $id; renew with \`palari ticket heartbeat $id\`"
	fi
	if [[ -n "$claim_ref" ]] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		git -C "$ROOT" show-ref --verify --quiet "$claim_ref" ||
			die "accept refused: missing claim ref $claim_ref for $id"
	fi
	lint_one_ticket "$file" >/dev/null
	cmd_report_lint "$id" >/dev/null
	ticket_evidence_complete "$id" || exit 1
	ticket_evidence_manifest_valid "$id" || exit 1
	# Forge-proof gate. When gate.enabled is true this is the acceptance
	# authority: signed implement/test/review attestations whose token
	# chains verify to the repository root key, with hash flow, dual
	# control by distinct keys, commit binding, and freshness. The string
	# checks below remain as UX guards only; they are not a security
	# boundary (see contracts/signed-acceptance.md).
	gate_require_accept "$id"
	[[ "$risk" == "R5" ]] && accept_r5_dual_human_enforcement_enabled && r5_dual_required="true"
	self_policy="$(cfg_nested acceptance implementation_self_acceptance "forbidden")"
	claimed_by="$(frontmatter_value "$file" claimed_by)"
	implemented_by="$(frontmatter_value "$file" implemented_by)"
	if [[ "$r5_dual_required" == "true" ]]; then
		accept_require_r5_dual_human "$id" "$by" "$co_by" "$claimed_by" "$implemented_by"
	fi
	if [[ "$self_policy" == "forbidden" ]]; then
		if same_actor "$by" "$claimed_by" || same_actor "$by" "$implemented_by"; then
			die "accept refused: implementation_self_acceptance is forbidden for $id"
		fi
		if [[ -n "$co_by" ]] && { same_actor "$co_by" "$claimed_by" || same_actor "$co_by" "$implemented_by"; }; then
			die "accept refused: implementation_self_acceptance is forbidden for $id"
		fi
	fi
	if [[ "$r5_dual_required" == "true" ]]; then
		accept_ensure_frontmatter_key "$file" co_accepted_by
		accept_ensure_frontmatter_key "$file" acceptance_mode
		update_frontmatter_scalars "$file" \
			"status"$'\035'"accepted"$'\034' \
			"accepted_by"$'\035'"$by"$'\034' \
			"co_accepted_by"$'\035'"$co_by"$'\034' \
			"acceptance_mode"$'\035'"human_dual"$'\034' \
			"accepted_at"$'\035'"$(now_utc)"$'\034' \
			"updated"$'\035'"$(today_utc)"$'\034'
	else
		update_frontmatter_scalars "$file" \
			"status"$'\035'"accepted"$'\034' \
			"accepted_by"$'\035'"$by"$'\034' \
			"accepted_at"$'\035'"$(now_utc)"$'\034' \
			"updated"$'\035'"$(today_utc)"$'\034'
	fi
	dest="$ROOT/$CLOSED_DIR/$(basename "$file")"
	mv "$file" "$dest"
	if [[ -n "$claim_ref" ]]; then
		git -C "$ROOT" update-ref -d "$claim_ref" >/dev/null 2>&1 || true
	fi
	printf 'accept: %s accepted by %s\n' "$id" "$by"
	[[ "$r5_dual_required" == "true" ]] && printf 'co-accepted-by: %s\n' "$co_by"
	printf 'closed: %s\n' "${dest#"$ROOT"/}"
}
