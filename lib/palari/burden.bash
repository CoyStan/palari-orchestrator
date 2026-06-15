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

cmd_burden() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	score) cmd_burden_score "$@" ;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari burden score WF-ID [--json]

Score Human Governance Load for a workflow. Read-only.
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
