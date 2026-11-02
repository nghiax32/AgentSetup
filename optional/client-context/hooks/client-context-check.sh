#!/usr/bin/env bash
# Client context staleness check for .claude/client-context/.
#
# Default mode (UserPromptSubmit hook): if any log file was added, changed or
# deleted since facts.md was last synced, prints a warning that is added to
# Claude's context. Prints nothing when the summary is up to date or when the
# project has no client context.
#
# --mark-synced: records the current log versions as synced. Called by the
# sync procedure in .claude/rules/client-context.md after updating facts.md.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CTX_DIR="$PROJECT_DIR/.claude/client-context"
MANIFEST=".synced"

[ "${1:-}" = "--mark-synced" ] || cat >/dev/null   # consume hook input

[ -d "$CTX_DIR/log" ] || exit 0
cd "$CTX_DIR" || exit 0

current="$(find log -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | xargs -r sha256sum)"

if [ "${1:-}" = "--mark-synced" ]; then
  printf '%s\n' "$current" > "$MANIFEST"
  echo "Marked $(printf '%s\n' "$current" | sed '/^$/d' | wc -l) log file(s) as synced."
  exit 0
fi

[ -z "$current" ] && exit 0

previous="$(cat "$MANIFEST" 2>/dev/null)"
[ -f facts.md ] && [ "$current" = "$previous" ] && exit 0

paths() { awk '{ $1=""; sub(/^ /,""); print }' | sed '/^$/d' | sort -u; }
prev_paths="$(printf '%s\n' "$previous" | paths)"
curr_paths="$(printf '%s\n' "$current" | paths)"
changed="$(comm -13 <(printf '%s\n' "$previous" | sort) <(printf '%s\n' "$current" | sort) | paths)"
deleted="$(comm -23 <(printf '%s\n' "$prev_paths") <(printf '%s\n' "$curr_paths") | sed '/^$/d')"

echo "<client-context-stale>"
if [ ! -f facts.md ]; then
  echo "Client logs exist in .claude/client-context/log/ but facts.md has not been created yet."
else
  echo "Client logs in .claude/client-context/ changed after facts.md was last synced, so facts.md may be out of date:"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if printf '%s\n' "$prev_paths" | grep -Fxq -- "$f"; then echo "- $f (modified)"; else echo "- $f (new)"; fi
  done <<< "$changed"
  while IFS= read -r f; do
    [ -n "$f" ] && echo "- $f (deleted)"
  done <<< "$deleted"
fi
echo "Do not rely on facts.md for this request until it is synced. Follow .claude/rules/client-context.md: run its sync procedure before any task that depends on client context, and always before producing client-facing output."
echo "</client-context-stale>"
exit 0
