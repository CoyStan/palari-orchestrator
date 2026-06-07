AUTHORITY_PROFILE="$(cfg authority_profile "team-safe")"

config_authority_profile_scalar() {
	local profile="$1"
	local key="$2"
	[[ -f "$CONFIG" ]] || return 1
	awk -v profile="$profile" -v key="$key" '
    function indent(line) {
      match(line, /[^ ]/)
      return RSTART ? RSTART - 1 : length(line)
    }
    $0 ~ "^authority_profiles:" {
      in_profiles = 1
      next
    }
    in_profiles {
      ind = indent($0)
      if (ind == 0 && $0 ~ "^[A-Za-z0-9_]+:") exit
      if (ind == 2 && $0 ~ "^[[:space:]]+[^:]+:") {
        name = $0
        sub("^[[:space:]]+", "", name)
        sub(":.*$", "", name)
        in_profile = (name == profile)
        next
      }
      if (in_profile && ind == 4) {
        name = $0
        sub("^[[:space:]]+", "", name)
        split(name, parts, ":")
        if (parts[1] == key) {
          sub("^[^:]*:[[:space:]]*", "", name)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
          gsub(/^["'\'']|["'\'']$/, "", name)
          print name
          exit
        }
      }
    }
  ' "$CONFIG"
}

authority_default_value() {
	local profile="$1"
	local key="$2"
	case "$profile:$key" in
	solo-founder:agent_can_commit) printf 'true\n' ;;
	solo-founder:agent_can_push_branch) printf 'true\n' ;;
	solo-founder:agent_can_open_pr) printf 'true\n' ;;
	solo-founder:agent_can_merge_main) printf 'true\n' ;;
	solo-founder:agent_can_accept) printf 'user-explicit\n' ;;
	team-safe:agent_can_commit) printf 'true\n' ;;
	team-safe:agent_can_push_branch) printf 'true\n' ;;
	team-safe:agent_can_open_pr) printf 'true\n' ;;
	team-safe:agent_can_merge_main) printf 'false\n' ;;
	team-safe:agent_can_accept) printf 'false\n' ;;
	strict:agent_can_commit) printf 'false\n' ;;
	strict:agent_can_push_branch) printf 'false\n' ;;
	strict:agent_can_open_pr) printf 'false\n' ;;
	strict:agent_can_merge_main) printf 'false\n' ;;
	strict:agent_can_accept) printf 'false\n' ;;
	*) printf 'false\n' ;;
	esac
}

authority_value() {
	local key="$1"
	local value
	value="$(config_authority_profile_scalar "$AUTHORITY_PROFILE" "$key" || true)"
	if [[ -n "$value" ]]; then
		printf '%s\n' "$value"
	else
		authority_default_value "$AUTHORITY_PROFILE" "$key"
	fi
}

authority_action_key() {
	case "$1" in
	commit) printf 'agent_can_commit\n' ;;
	push-branch | push) printf 'agent_can_push_branch\n' ;;
	open-pr | pr) printf 'agent_can_open_pr\n' ;;
	merge-main | merge) printf 'agent_can_merge_main\n' ;;
	accept | accept-ticket) printf 'agent_can_accept\n' ;;
	*) return 1 ;;
	esac
}
