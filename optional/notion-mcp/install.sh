#!/usr/bin/env bash
# Installs the notion-headless-mcp server from its zip and registers it with
# Claude Code at user scope, so it is available in every project on this machine.
#
# Usage: optional/notion-mcp/install.sh <notion-headless-mcp.zip>
#
# Install directory: $NOTION_MCP_DIR (default ~/tools/notion-headless-mcp).
# Safe to run again, for example after a new version of the zip or after
# switching Node versions: the code is refreshed, the saved Notion session
# (config.json) is kept, and the registration is replaced.

set -euo pipefail

ZIP="${1:?usage: $0 <notion-headless-mcp.zip>}"
DIR="${NOTION_MCP_DIR:-$HOME/tools/notion-headless-mcp}"
NAME=notion

[ -f "$ZIP" ] || { echo "not a file: $ZIP" >&2; exit 1; }
for cmd in node npm npx claude python3 jq; do
  command -v "$cmd" >/dev/null || { echo "$cmd is required" >&2; exit 1; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. Extract. The zip is built on Windows with backslash separators, which
#    unzip on Linux turns into flat file names, so extract with Python instead.
echo "==> Extracting $ZIP"
python3 -I - "$ZIP" "$TMP" <<'PY'
import os, posixpath, sys, zipfile

src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(src) as z:
    for info in z.infolist():
        name = info.filename.replace("\\", "/")
        norm = posixpath.normpath(name)
        if name.startswith("/") or norm == ".." or norm.startswith("../"):
            sys.exit(f"unsafe path in archive: {info.filename}")
        target = os.path.join(dst, norm)
        if name.endswith("/"):
            os.makedirs(target, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with z.open(info) as s, open(target, "wb") as d:
            d.write(s.read())
PY

ROOT=""
while IFS= read -r pkg; do
  if [ "$(jq -r '.name // empty' "$pkg")" = "notion-headless-mcp" ]; then ROOT="$(dirname "$pkg")"; break; fi
done < <(find "$TMP" -maxdepth 3 -name package.json -not -path '*/node_modules/*')
[ -n "$ROOT" ] || { echo "no notion-headless-mcp package.json found in $ZIP" >&2; exit 1; }

# Never take a session token or dependencies from the archive.
rm -rf "$ROOT/config.json" "$ROOT/node_modules"

# 2. Copy into place, keeping the existing config.json (Notion session) and node_modules.
echo "==> Installing into $DIR"
mkdir -p "$DIR"
rm -rf "$DIR/src"
cp -a "$ROOT/." "$DIR/"

# 3. Dependencies, and the Chromium build used by the login popup.
echo "==> Installing dependencies"
if [ -f "$DIR/package-lock.json" ]; then
  (cd "$DIR" && npm ci --no-audit --no-fund)
else
  (cd "$DIR" && npm install --no-audit --no-fund)
fi
(cd "$DIR" && npx --no-install playwright install chromium)

# 4. Register with Claude Code at user scope, with the current Node binary.
NODE="$(command -v node)"
echo "==> Registering MCP server '$NAME' (user scope) with $NODE"
claude mcp remove -s user "$NAME" >/dev/null 2>&1 || true
claude mcp add -s user "$NAME" -- "$NODE" "$DIR/src/index.js"

# 5. Notion session.
if [ -f "$DIR/config.json" ] && [ -n "$(jq -r '.token_v2 // empty' "$DIR/config.json" 2>/dev/null)" ]; then
  echo "==> Existing Notion session kept ($DIR/config.json)"
else
  echo "==> No Notion session yet: a login window opens on first use, or run: (cd \"$DIR\" && npm run login)"
fi

echo "Done. Restart Claude Code sessions to pick up the server; check it with: claude mcp get $NAME"
