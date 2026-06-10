# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash, which defines shared globals.
#
# Forge-proof accept gate. The cryptography lives in the vendored kernel at
# gate/forgegate and the adapter at adapters/gate/palari_gate.py. This module
# only routes commands, guards acceptance, and feeds the snapshot. It never
# reimplements verification.

GATE_ADAPTER_REL="adapters/gate/palari_gate.py"

gate_enabled() {
	[[ "$(cfg_nested gate enabled "false")" == "true" ]]
}

gate_adapter_path() {
	printf '%s/%s' "$ROOT" "$GATE_ADAPTER_REL"
}

gate_available() {
	command -v python3 >/dev/null 2>&1 || return 1
	[[ -f "$(gate_adapter_path)" ]] || return 1
	[[ -d "$ROOT/gate/forgegate" ]] || return 1
	python3 - "$ROOT/gate" <<'PY' >/dev/null 2>&1 || return 1
import sys
sys.path.insert(0, sys.argv[1])
import forgegate  # noqa: F401
PY
	return 0
}

gate_run() {
	python3 -B "$(gate_adapter_path)" --root "$ROOT" "$@"
}

# Refuses acceptance unless the cryptographic gate accepts the ticket.
# Fails closed: an enabled gate with an unavailable kernel refuses too.
gate_require_accept() {
	local ticket_id="$1"
	gate_enabled || return 0
	if ! gate_available; then
		die "accept refused: gate is enabled but the forgegate kernel is unavailable (python3 with the 'cryptography' package is required); acceptance fails closed"
	fi
	if ! gate_run verify "$ticket_id"; then
		die "accept refused: the forge-proof gate refused $ticket_id; see reasons above. Acceptance requires signed implement, test, and review attestations that verify to the repository root key."
	fi
	printf 'accept gate: %s ACCEPTED by the forge-proof gate\n' "$ticket_id"
}

# Best-effort auto-attestation of the test step after a green CI run.
# Quiet no-op when the gate is off; prints the exact next command when the
# honest chain is not ready instead of guessing.
gate_ci_attest_test() {
	local ticket_id="$1"
	gate_enabled || return 0
	if ! gate_available; then
		printf 'ci gate: gate is enabled but the kernel is unavailable; test step left unattested\n' >&2
		return 0
	fi
	local ci_key
	ci_key="$(cfg_nested gate ci_key "ci")"
	if [[ ! -f "$ROOT/$(cfg_nested gate keys_dir ".palari/gate/keys")/$ci_key-$ticket_id.token.json" ]]; then
		printf 'ci gate: no %s token for %s; run `./bin/palari gate setup-ticket %s` to enable signed evidence\n' "$ci_key" "$ticket_id" "$ticket_id"
		return 0
	fi
	if gate_run attest-test "$ticket_id"; then
		return 0
	fi
	printf 'ci gate: test step not attested; complete `./bin/palari gate attest-implement %s` first\n' "$ticket_id" >&2
	return 0
}

snapshot_gate_json() {
	if gate_available; then
		gate_run status 2>/dev/null && return 0
	fi
	printf '{"enabled":%s,"available":false,"initialized":false,"root_fingerprint":"","layout":' \
		"$(json_bool "$(cfg_nested gate enabled "false")")"
	json_string "$(cfg_nested gate layout "layouts/palari-change.yml")"
	printf ',"tickets":{}}'
}

gate_doctor_report() {
	if gate_enabled; then
		if gate_available; then
			printf 'gate: enabled, kernel available\n'
			if [[ -f "$ROOT/$(cfg_nested gate root_pub_file ".palari/gate/root.pub")" ]]; then
				printf 'gate: root public key present\n'
			else
				printf 'gate: not initialized; run `./bin/palari gate init`\n'
			fi
		else
			printf 'gate: ENABLED BUT UNAVAILABLE; acceptance will fail closed until python3 + cryptography are installed\n'
		fi
	else
		printf 'gate: disabled; acceptance relies on the honor-system manifest. Enable gate.enabled in palari.config.yaml for forge-proof acceptance.\n'
	fi
}

cmd_gate() {
	local sub="${1:-}"
	case "$sub" in
	-h | --help | help | "")
		cat <<'GATEUSAGE'
usage: palari gate COMMAND [ARGS]

Forge-proof accept gate: signed attestations, narrowing delegation tokens,
and a layout-verified verdict. See contracts/signed-acceptance.md.

commands:
  init [--force]                 Create root + orchestrator keys and token.
  setup-ticket ID [--days N]     Grant implement, test, and review tokens.
  grant --ticket ID --holder NAME --steps a,b
                                 Grant a custom step token.
  attest-implement ID            Sign the ticket diff (implementer key).
  attest-test ID                 Sign the CI evidence bundle (ci key).
  attest-review ID               Sign the fresh review (reviewer key).
  attest --ticket ID --step S --key NAME [--input n=p] [--output n=p]
         [--consumes STEP]       Low-level attestation with explicit artifacts.
  verify ID [--json]             Run the gate; exits 0 ACCEPTED, 1 REFUSED.
  status [--ticket ID] [--pretty]
                                 JSON gate status (used by snapshot).
GATEUSAGE
		return 0
		;;
	esac
	if ! command -v python3 >/dev/null 2>&1; then
		die "palari gate requires python3 with the 'cryptography' package"
	fi
	[[ -f "$(gate_adapter_path)" ]] || die "missing gate adapter: $GATE_ADAPTER_REL"
	gate_run "$@"
}
