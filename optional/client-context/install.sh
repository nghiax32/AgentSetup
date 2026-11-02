#!/usr/bin/env bash
# Installs client context tracking into a project that already uses this setup.
#
# Usage: optional/client-context/install.sh <project-dir>
#
# - copies the rule and the staleness hook into <project-dir>/.claude/
# - registers the hook in <project-dir>/.claude/settings.local.json
# - adds the rule and the facts.md import to <project-dir>/CLAUDE.local.md
# - keeps client data and these local files out of git via .git/info/exclude
#
# Safe to run again: files are refreshed and nothing is added twice.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="$(cd "${1:?usage: $0 <project-dir>}" && pwd)"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# 1. Rule and hook
mkdir -p "$DST/.claude/rules" "$DST/.claude/hooks"
cp "$SRC/rules/client-context.md" "$DST/.claude/rules/"
cp "$SRC/hooks/client-context-check.sh" "$DST/.claude/hooks/"
chmod 755 "$DST/.claude/hooks/client-context-check.sh"

# 2. Hook registration (settings.local.json is merged with settings.json by Claude Code)
settings="$DST/.claude/settings.local.json"
[ -s "$settings" ] || echo '{}' > "$settings"
cmd='"$CLAUDE_PROJECT_DIR"/.claude/hooks/client-context-check.sh'
if ! jq -e --arg c "$cmd" '[.. | objects | select(.command? == $c)] | length > 0' "$settings" >/dev/null; then
  tmp="$(mktemp)"
  jq --arg c "$cmd" '.hooks.UserPromptSubmit += [{hooks: [{type: "command", command: $c, timeout: 10}]}]' \
    "$settings" > "$tmp" && mv "$tmp" "$settings"
fi

# 3. Instructions for the agent
local_md="$DST/CLAUDE.local.md"
if ! grep -qs 'rules/client-context.md' "$local_md"; then
  [ -s "$local_md" ] && printf '\n' >> "$local_md"
  cat >> "$local_md" <<'EOF'
## Client context

Follow `.claude/rules/client-context.md`: record client messages verbatim in dated logs; sync and cite `facts.md` before relying on client context or producing client-facing output. If the file below does not exist yet, there is no recorded client context.

@.claude/client-context/facts.md
EOF
fi

# 4. Keep client data and local setup out of version control
if exclude="$(git -C "$DST" rev-parse --git-path info/exclude 2>/dev/null)"; then
  case "$exclude" in /*) ;; *) exclude="$DST/$exclude" ;; esac
  mkdir -p "$(dirname "$exclude")"
  for p in .claude/client-context/ .claude/rules/client-context.md .claude/hooks/client-context-check.sh \
           .claude/settings.local.json CLAUDE.local.md; do
    grep -qxF "$p" "$exclude" 2>/dev/null || echo "$p" >> "$exclude"
  done
else
  echo "warning: $DST is not a git repository; keep .claude/client-context/ out of version control yourself" >&2
fi

echo "Client context tracking installed in $DST"
echo "Record client messages under $DST/.claude/client-context/log/ (created on first use)."
