#!/usr/bin/env bash
# Merges user/settings.json into the user-level Claude Code settings
# (~/.claude/settings.json), which apply to every project on this machine.
#
# Usage: user/apply.sh [target-settings-file]
#
# Keys in user/settings.json are deep-merged: they are added or overwritten,
# and every other existing setting is kept. A timestamped backup of the target
# is written next to it first. Safe to run again.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/settings.json"
DST="${1:-$HOME/.claude/settings.json}"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

mkdir -p "$(dirname "$DST")"
[ -s "$DST" ] || echo '{}' > "$DST"
jq -e . "$DST" >/dev/null || { echo "$DST is not valid JSON; fix it first" >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq -s '.[0] * .[1]' "$DST" "$SRC" > "$tmp"

if jq -e --slurpfile a "$DST" --slurpfile b "$tmp" -n '$a == $b' >/dev/null; then
  echo "$DST already up to date"
  exit 0
fi

backup="$DST.bak.$(date +%Y%m%d-%H%M%S)"
cp "$DST" "$backup"
cat "$tmp" > "$DST"
echo "Updated $DST (backup: $backup)"
