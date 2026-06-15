# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and directory globals are sourced from core.bash.

hgl_adapter_args() {
	local workflow="$1"
	shift
	python3 "$ROOT/adapters/planning/hgl.py" \
		--root "$ROOT" \
		--workflow "$workflow" \
		--workflows-proposed-dir "$WORKFLOWS_PROPOSED_DIR" \
		--workflows-active-dir "$WORKFLOWS_ACTIVE_DIR" \
		--workflows-closed-dir "$WORKFLOWS_CLOSED_DIR" \
		--humans-active-dir "$HUMANS_ACTIVE_DIR" \
		"$@"
}

debt_adapter_args() {
	python3 "$ROOT/adapters/planning/governance_debt.py" \
		--root "$ROOT" \
		--workflows-proposed-dir "$WORKFLOWS_PROPOSED_DIR" \
		--workflows-active-dir "$WORKFLOWS_ACTIVE_DIR" \
		--workflows-closed-dir "$WORKFLOWS_CLOSED_DIR" \
		--humans-active-dir "$HUMANS_ACTIVE_DIR" \
		--tickets-open-dir "$OPEN_DIR" \
		--tickets-closed-dir "$CLOSED_DIR" \
		--decisions-decided-dir "$DECISIONS_DECIDED_DIR" \
		--outcomes-recorded-dir "$OUTCOMES_RECORDED_DIR" \
		"$@"
}

cmd_burden_score() {
	local workflow="${1:-}"
	shift || true
	[[ -n "$workflow" ]] || die "burden score requires WF-ID"
	local json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			json="true"
			shift
			;;
		*) die "unknown burden score option: $arg" ;;
		esac
	done
	if [[ "$json" == "true" ]]; then
		hgl_adapter_args "$workflow" --json
	else
		hgl_adapter_args "$workflow"
	fi
}

cmd_burden_debt() {
	local json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			json="true"
			shift
			;;
		*) die "unknown burden debt option: $arg" ;;
		esac
	done
	if [[ "$json" == "true" ]]; then
		debt_adapter_args --json
	else
		debt_adapter_args
	fi
}

cmd_burden() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	score) cmd_burden_score "$@" ;;
	debt) cmd_burden_debt "$@" ;;
	help | -h | --help | "")
		cat <<'USAGE'
usage:
  palari burden score WF-ID [--json]
  palari burden debt [--json]

Score Human Governance Load for a workflow or report Human Governance Debt.
Read-only.
USAGE
		;;
	*) die "unknown burden command: $sub" ;;
	esac
}

cmd_human_coverage() {
	local workflow="${1:-}"
	shift || true
	[[ -n "$workflow" ]] || die "human coverage requires WF-ID"
	local json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			json="true"
			shift
			;;
		*) die "unknown human coverage option: $arg" ;;
		esac
	done
	if [[ "$json" == "true" ]]; then
		hgl_adapter_args "$workflow" --coverage-only --json
	else
		hgl_adapter_args "$workflow" --coverage-only
	fi
}
