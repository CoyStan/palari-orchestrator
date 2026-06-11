#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf 'autonomy-roles: %s\n' "$*" >&2
	exit 1
}

roles=(
	ROLE-PRODUCT-LEAD
	ROLE-DESIGN-LEAD
	ROLE-QA-LEAD
	ROLE-RELEASE-LEAD
	ROLE-AUTONOMY-COORDINATOR
)

for role in "${roles[@]}"; do
	file="$(find "$ROOT/roles/proposed" -maxdepth 1 -type f -name "$role-*.md" | head -n 1)"
	[[ -n "$file" ]] || fail "missing proposed role: $role"
	grep -Fq "status: proposed" "$file" || fail "$role is not proposed"
	grep -Fq "parent_role: ROLE-ROOT" "$file" || fail "$role parent is not ROLE-ROOT"
	grep -Fq "may_accept_tickets: false" "$file" || fail "$role may accept tickets"
	grep -Fq "prod/**" "$file" || fail "$role missing production forbidden path"
	grep -Fq "**/*secret*" "$file" || fail "$role missing secret forbidden path"
	grep -Fq "authority unclear" "$file" || fail "$role missing authority escalation"
done

grep -Fq "may_create_roles: proposed-only" "$ROOT/roles/proposed/ROLE-AUTONOMY-COORDINATOR-autonomy-coordinator.md" ||
	fail "autonomy coordinator should only propose roles"

grep -Fq "external account, credential" "$ROOT/roles/proposed/ROLE-RELEASE-LEAD-release-lead.md" ||
	fail "release lead should escalate external account blockers"

grep -Fq "Founder Operator Role Proposals" "$ROOT/docs/autonomy/founder-operator-roles.md" ||
	fail "missing autonomy role guide"

"$ROOT/bin/palari" role lint >/tmp/palari-autonomy-role-lint.out
grep -Fq "role lint: ok" /tmp/palari-autonomy-role-lint.out

printf 'autonomy-roles: ok\n'
