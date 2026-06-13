# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT is sourced from bin/palari.

cmd_state() {
	local mode="print" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--path)
			mode="path"
			shift
			;;
		-h | --help)
			cat <<'USAGE'
usage: palari state [--path]

Print the landed capability map for collaborators and agents.

  --path   Print the state document path instead of its contents.
USAGE
			return 0
			;;
		*) die "unknown state option: $arg" ;;
		esac
	done

	local state_file="$ROOT/STATE.md"
	[[ -f "$state_file" ]] || die "missing STATE.md; create a landed capability map first"
	if [[ "$mode" == "path" ]]; then
		printf '%s\n' "$state_file"
	else
		cat "$state_file"
	fi
}
