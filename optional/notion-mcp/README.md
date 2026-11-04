# Notion MCP (optional)

Lets the agent read Notion pages through [`notion-headless-mcp`](#getting-the-zip), an MCP server with two tools: `notion_read_page` (page as Markdown in the chat) and `notion_export_to_md` (page saved as a `.md` file in the project).

**Scope: the whole machine.** The server is registered at Claude Code's user scope, so once installed it is available in every project; a new project needs no setup.

## Install

```bash
optional/notion-mcp/install.sh path/to/notion-headless-mcp.zip
```

Requirements: `node`, `npm`, `claude`, `python3` and `jq`.

| Step | Result |
|---|---|
| Extracts the zip (built on Windows, so with backslash paths that `unzip` cannot handle) | Files under `~/tools/notion-headless-mcp/` (override with `NOTION_MCP_DIR`) |
| Installs dependencies and Playwright's Chromium | `node_modules/`, browser for the login popup |
| Registers the server with the current Node binary | `notion` in `~/.claude.json`, user scope |
| Keeps the saved Notion session | `config.json` is never overwritten, and never taken from the zip |

Run it again after a new version of the zip, or after switching Node versions with `nvm`: the registration points at an absolute Node path, so it breaks when that Node is removed.

## Login

The session token (`token_v2`) is captured automatically: on first use, or when the session expires, a small browser window opens for you to log in to Notion once. To log in ahead of time:

```bash
cd ~/tools/notion-headless-mcp && npm run login
```

The token stays in `~/tools/notion-headless-mcp/config.json` on this machine. Never commit it or paste it into a chat.

## Check and remove

```bash
claude mcp get notion            # registration and status
claude mcp remove -s user notion # unregister
```

## Getting the zip

The server is an internal tool distributed as `notion-headless-mcp.zip`; it is not included in this repository. Ask the team for the current version.
