# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT/EVIDENCE_DIR are sourced from core.bash.
#
# Broker commands are mock-only in this slice. They capture evidence for
# observed commands but do not enable real side-effect authority.

broker_run_id() {
	printf 'RUN-%s-%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" "$BASHPID"
}

cmd_broker_run() {
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "broker run requires TICKET-ID"
	local mock="false"
	while (($# > 0)); do
		case "$1" in
		--mock)
			mock="true"
			shift
			;;
		--)
			shift
			break
			;;
		*) die "unknown broker run option before --: $1" ;;
		esac
	done
	[[ "$mock" == "true" ]] || die "broker run is mock-only in this version; pass --mock"
	(($# > 0)) || die "broker run requires a command after --"
	local file ticket_id out_dir run_id
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	run_id="$(broker_run_id)"
	out_dir="$ROOT/$EVIDENCE_DIR/$ticket_id/broker/$run_id"
	python3 -B "$ROOT/adapters/broker/mock_broker.py" run \
		--root "$ROOT" \
		--ticket "$ticket_id" \
		--out "$out_dir" \
		-- "$@"
}

cmd_broker_evidence() {
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "broker evidence requires TICKET-ID"
	local json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			json="true"
			shift
			;;
		*) die "unknown broker evidence option: $arg" ;;
		esac
	done
	local file ticket_id args
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	args=(evidence --root "$ROOT" --ticket "$ticket_id" --evidence-dir "$EVIDENCE_DIR")
	if [[ "$json" == "true" ]]; then
		args+=(--json)
	fi
	python3 -B "$ROOT/adapters/broker/mock_broker.py" "${args[@]}"
}

cmd_broker_status() {
	cat <<'STATUS'
Broker status
mode: mock-only
real_side_effects_enabled: false
credentials_available_to_agents: false
network_or_hosted_api_access: false
note: broker run requires --mock and records evidence under reports/evidence/TICKET/broker/.
STATUS
}

cmd_broker() {
	local sub="${1:-status}"
	shift || true
	case "$sub" in
	run) cmd_broker_run "$@" ;;
	evidence) cmd_broker_evidence "$@" ;;
	status | "") cmd_broker_status "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari broker run TICKET-ID --mock -- COMMAND [ARGS...]
       palari broker evidence TICKET-ID [--json]
       palari broker status

Broker support is mock-only. It captures observed-command evidence and keeps
real_side_effects_enabled: false.
USAGE
		;;
	*) die "unknown broker command: $sub" ;;
	esac
}
