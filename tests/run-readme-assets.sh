#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf 'readme-assets: %s\n' "$*" >&2
	exit 1
}

mapfile -t assets < <(grep -Eo 'assets/readme/[^") ]+' README.md | LC_ALL=C sort -u)
((${#assets[@]} > 0)) || fail "README references no assets/readme files"

for asset in "${assets[@]}"; do
	[[ -f "$asset" ]] || fail "missing README asset: $asset"
	attr="$(git check-attr export-ignore -- "$asset" | awk -F': ' '{print $3}')"
	[[ "$attr" != "set" ]] || fail "README asset is export-ignored: $asset"
done

printf 'readme-assets: ok (%s asset(s))\n' "${#assets[@]}"
