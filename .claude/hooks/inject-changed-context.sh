#!/usr/bin/env bash
# UserPromptSubmit hook: injects CLAUDE.md files, .claude/skills/** and .claude/rules/** into
# Claude's context whenever they are added, changed, or deleted.
#
# - First prompt of a session: records a baseline silently (Claude Code already
#   loads CLAUDE.md at session start; skills are loaded fresh when invoked).
# - Later prompts: prints full content of changed/new files and lists deleted
#   ones. Stdout from this hook is added to Claude's context.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.claude/.context-cache"
MAX_BYTES=30000   # files larger than this are announced, not inlined

input="$(cat)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "default"' 2>/dev/null || echo default)"
[ -z "$session_id" ] && session_id=default

mkdir -p "$STATE_DIR"
state_file="$STATE_DIR/$session_id.sha"

# Remove state from sessions older than 7 days
find "$STATE_DIR" -name '*.sha' -mtime +7 -delete 2>/dev/null

cd "$PROJECT_DIR" || exit 0

# Collect watched files (paths relative to project dir)
current="$(
  {
    find . \( -name .git -o -name node_modules -o -name .context-cache \) -prune -o \
      \( -name 'CLAUDE.md' -o -name 'CLAUDE.local.md' \) -type f -print
    [ -d .claude/skills ] && find .claude/skills -type f -print
    [ -d .claude/rules ] && find .claude/rules -type f -print
  } 2>/dev/null | sed 's|^\./||' | sort -u | while IFS= read -r f; do
    sha256sum "$f" 2>/dev/null
  done
)"

if [ ! -f "$state_file" ]; then
  printf '%s\n' "$current" > "$state_file"
  exit 0
fi

previous="$(cat "$state_file")"
printf '%s\n' "$current" > "$state_file"

[ "$current" = "$previous" ] && exit 0

# Determine changed/new and deleted files
changed="$(comm -13 <(printf '%s\n' "$previous" | sort) <(printf '%s\n' "$current" | sort) | awk '{ $1=""; sub(/^ /,""); print }')"
prev_paths="$(printf '%s\n' "$previous" | awk '{ $1=""; sub(/^ /,""); print }' | sort -u)"
curr_paths="$(printf '%s\n' "$current"  | awk '{ $1=""; sub(/^ /,""); print }' | sort -u)"
deleted="$(comm -23 <(printf '%s\n' "$prev_paths") <(printf '%s\n' "$curr_paths") | sed '/^$/d')"

echo "<watched-files-updated>"
echo "The user changed watched context files since your last turn. The content below is the CURRENT version on disk and supersedes anything earlier in context. Follow the updated instructions."

if [ -n "$changed" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    status="modified"
    printf '%s\n' "$prev_paths" | grep -Fxq -- "$f" || status="new"
    size=$(wc -c < "$f")
    echo
    if [ "$size" -gt "$MAX_BYTES" ]; then
      echo "=== $f ($status, ${size} bytes, too large to inline — Read it with a tool) ==="
    elif ! grep -Iq . "$f" 2>/dev/null && [ "$size" -gt 0 ]; then
      echo "=== $f ($status, binary file, not inlined) ==="
    else
      echo "=== $f ($status) ==="
      cat "$f"
      echo
      echo "=== end $f ==="
    fi
  done <<< "$changed"
fi

if [ -n "$deleted" ]; then
  echo
  echo "Deleted files (ignore their earlier content):"
  printf '%s\n' "$deleted" | sed 's/^/- /'
fi

echo "</watched-files-updated>"
exit 0
