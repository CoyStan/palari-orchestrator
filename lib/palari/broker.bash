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
	local mock="false" sandbox="false"
	while (($# > 0)); do
		case "$1" in
		--mock)
			mock="true"
			shift
			;;
		--sandbox)
			sandbox="true"
			shift
			;;
		--)
			shift
			break
			;;
		*) die "unknown broker run option before --: $1" ;;
		esac
	done
	if [[ "$mock" == "true" && "$sandbox" == "true" ]]; then
		die "broker run accepts only one mode: --mock or --sandbox"
	fi
	[[ "$mock" == "true" || "$sandbox" == "true" ]] || die "broker run is mock/sandbox only in this version; pass --mock or --sandbox"
	(($# > 0)) || die "broker run requires a command after --"
	local file ticket_id out_dir run_id
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	run_id="$(broker_run_id)"
	out_dir="$ROOT/$EVIDENCE_DIR/$ticket_id/broker/$run_id"
	local adapter_command="run"
	[[ "$sandbox" == "true" ]] && adapter_command="sandbox"
	python3 -B "$ROOT/adapters/broker/mock_broker.py" "$adapter_command" \
		--root "$ROOT" \
		--ticket "$ticket_id" \
		--out "$out_dir" \
		-- "$@"
}

cmd_broker_sandbox() {
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "broker sandbox requires TICKET-ID"
	if [[ "${1:-}" == "--" ]]; then
		shift
	fi
	(($# > 0)) || die "broker sandbox requires a command after --"
	cmd_broker_run "$ticket" --sandbox -- "$@"
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
mode: mock-and-local-sandbox
real_side_effects_enabled: false
credentials_available_to_agents: false
network_or_hosted_api_access: false
network_isolation_enforced: false
note: broker run requires --mock or --sandbox and records evidence under reports/evidence/TICKET/broker/.
STATUS
}

cmd_broker() {
	local sub="${1:-status}"
	shift || true
	case "$sub" in
	run) cmd_broker_run "$@" ;;
	sandbox) cmd_broker_sandbox "$@" ;;
	evidence) cmd_broker_evidence "$@" ;;
	status | "") cmd_broker_status "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari broker run TICKET-ID --mock -- COMMAND [ARGS...]
       palari broker run TICKET-ID --sandbox -- COMMAND [ARGS...]
       palari broker sandbox TICKET-ID -- COMMAND [ARGS...]
       palari broker evidence TICKET-ID [--json]
       palari broker status

Broker support is mock/local-sandbox only. It captures evidence and keeps
real_side_effects_enabled: false. Local sandbox mode runs in a disposable repo
copy and does not copy changes back.
USAGE
		;;
	*) die "unknown broker command: $sub" ;;
	esac
}
