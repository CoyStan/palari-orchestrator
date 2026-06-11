#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$HOME/.codex/prompts}"
mkdir -p "$DEST"
cp "$HERE"/prompts/*.md "$DEST"/
printf 'palari codex prompts installed to %s:\n' "$DEST"
for f in "$DEST"/palari-*; do
	printf '  %s\n' "$(basename "$f")"
done
printf 'Authority stays in the repository: AGENTS.md, tickets, and bin/palari gates.\n'
