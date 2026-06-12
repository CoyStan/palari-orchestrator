# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and config globals are sourced from core.bash.
#
# Model routing maps work to the cheapest model that can do it honestly.
# Resolution has three layers, each overridable in palari.config.yaml:
#
#   risk tier  -> model class   (model_class_r1: fast, ... default mapping)
#   ticket     -> model_hint    (optional frontmatter: a class or exact model)
#   class      -> executor model (model_<class>_<executor>: provider string)
#
# Routing only ever produces a *suggestion* that `agent run` applies when no
# explicit --model is given; an explicit --model always wins, and an empty
# resolution falls through to the executor's own default. The resolved model
# is recorded into the run's evidence directory so cost can be attributed
# per accepted ticket.

MODEL_CLASSES="fast balanced frontier"

model_routing_enabled() {
	[[ "$(cfg model_routing_enabled "true")" == "true" ]]
}

model_class_for_risk() {
	local risk="$1"
	case "$risk" in
	R1) cfg model_class_r1 "fast" ;;
	R2) cfg model_class_r2 "balanced" ;;
	R3) cfg model_class_r3 "frontier" ;;
	R4) cfg model_class_r4 "frontier" ;;
	*) cfg model_class_default "balanced" ;;
	esac
}

model_is_class() {
	local value="$1" class
	for class in $MODEL_CLASSES; do
		[[ "$value" == "$class" ]] && return 0
	done
	return 1
}

model_for_class_executor() {
	# Map a class to a concrete model string for one executor. Empty means
	# "no mapping configured; use the executor's default model".
	local class="$1" executor="$2"
	case "$executor" in
	opencode | codex | claude | mock | openrouter) ;;
	*) executor="generic" ;;
	esac
	local value
	value="$(cfg "model_${class}_${executor}" "")"
	[[ -n "$value" ]] || value="$(cfg "model_${class}_generic" "")"
	printf '%s' "$value"
}

ticket_model_class() {
	# The class a ticket routes to: explicit class hint wins, then risk tier.
	local file="$1"
	local hint
	hint="$(frontmatter_value "$file" model_hint)"
	if [[ -n "$hint" ]] && model_is_class "$hint"; then
		printf '%s' "$hint"
		return 0
	fi
	model_class_for_risk "$(frontmatter_value "$file" risk)"
}

resolve_ticket_model() {
	# Print the concrete model string for a ticket and executor, or nothing
	# when the executor default should be used. An exact (non-class)
	# model_hint is passed through verbatim.
	local file="$1" executor="$2"
	model_routing_enabled || return 0
	local hint
	hint="$(frontmatter_value "$file" model_hint)"
	if [[ -n "$hint" ]] && ! model_is_class "$hint"; then
		printf '%s' "$hint"
		return 0
	fi
	model_for_class_executor "$(ticket_model_class "$file")" "$executor"
}

cmd_model_routes() {
	printf 'model routing: %s\n' "$(model_routing_enabled && printf 'enabled' || printf 'disabled')"
	printf '\nrisk tier -> class\n'
	local tier
	for tier in R1 R2 R3 R4; do
		printf '  %-3s -> %s\n' "$tier" "$(model_class_for_risk "$tier")"
	done
	printf '\nclass -> model (per executor; blank = executor default)\n'
	local class executor value
	for class in $MODEL_CLASSES; do
		for executor in opencode codex claude openrouter generic; do
			value="$(cfg "model_${class}_${executor}" "")"
			[[ -n "$value" ]] || continue
			printf '  %-9s %-9s %s\n' "$class" "$executor" "$value"
		done
	done
	printf '\noverride per ticket with frontmatter model_hint (a class or exact model),\nor per run with: ./bin/palari agent run ID --executor E --model NAME\n'
}

cmd_model_show() {
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "model show requires a ticket ID"
	local executor="opencode" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--executor)
			executor="$2"
			shift 2
			;;
		*) die "unknown model show option: $arg" ;;
		esac
	done
	local file class resolved hint
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	class="$(ticket_model_class "$file")"
	resolved="$(resolve_ticket_model "$file" "$executor")"
	hint="$(frontmatter_value "$file" model_hint)"
	printf 'ticket: %s\n' "$(frontmatter_value "$file" id)"
	printf 'risk: %s\n' "$(frontmatter_value "$file" risk)"
	printf 'model_hint: %s\n' "${hint:-"(none)"}"
	printf 'class: %s\n' "$class"
	printf 'executor: %s\n' "$executor"
	printf 'resolved model: %s\n' "${resolved:-"(executor default)"}"
	printf 'run with: ./bin/palari agent run %s --executor %s%s\n' \
		"$(frontmatter_value "$file" id)" "$executor" \
		"${resolved:+ --model $resolved}"
}

cmd_model() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	routes)
		cmd_model_routes "$@"
		;;
	show)
		cmd_model_show "$@"
		;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari model SUBCOMMAND

  routes                         Show the routing table: risk -> class -> model.
  show TICKET [--executor E]     Resolve the model a ticket would run with.

Routing sends each ticket to the cheapest model class that matches its risk
tier (R1 -> fast, R2 -> balanced, R3/R4 -> frontier by default). Configure in
palari.config.yaml (model_class_rN, model_<class>_<executor>,
model_routing_enabled). A ticket can override with frontmatter `model_hint`
(a class name or an exact model string); an explicit `agent run --model`
always wins. The resolved model is recorded into run evidence.
USAGE
		;;
	*) die "unknown model command: $sub" ;;
	esac
}
