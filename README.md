# AgentSetup

A reusable [Claude Code](https://claude.com/claude-code) setup: project rules, hooks and a status line that make the agent predictable to work with. Copy it into a project to get the same behaviour everywhere.

## Why

Out of the box, a coding agent tends to act on questions, commit and push without being asked, stage unrelated files, and report what it believes happened rather than what did. This setup turns those preferences into explicit rules that the agent reads before it acts, and adds hooks so that rule changes take effect in a running session without a restart.

## Layout

| Path | Contents | Use for |
|---|---|---|
| `CLAUDE.md`, `.claude/` | The common setup: rules, context hook and status line | Every project, including personal ones |
| `user/` | User-level Claude Code settings that everyone should apply, and the script that applies them | Once per machine |
| `optional/` | Add-ons you install only when needed, each with its own installer and README stating its scope | See below |

## What's included

### Rules (`.claude/rules/`)

One rule per file, listed in `CLAUDE.md` so the agent knows which to read for a given task.

| Rule | Summary |
|---|---|
| `answer-questions-dont-act.md` | A question gets an answer, not a change. Act only on an explicit instruction, and only as far as requested |
| `commit-pr-only-when-asked.md` | Commit, push and PR operations only on a specific request, one step at a time. Stage files by path; never commit `.gitignore` unless asked |
| `commit-authorship.md` | Commits are authored by the person accountable for the change; commit messages and PR text carry no tool-generated trailers or footers |
| `commit-pr-report-table.md` | Verify the real git and GitHub state before reporting a commit or PR, and report it as a fixed table |

### Hooks (`.claude/hooks/`)

- `inject-changed-context.sh` (`UserPromptSubmit`): when `CLAUDE.md`, a rule or a skill changes during a session, injects the new content into the next prompt so the agent follows the current version.

### Status line (`.claude/statusline.sh`)

Shows the model, its effort level and the Claude.ai plan usage:

```
Opus 4.8 (medium) · Session 42% (resets in 1h23m, 15:10) · Week 18% (resets in 3d4h, Mon 09:00)
```

### User-level settings (`user/`)

Some settings belong in `~/.claude/settings.json`, so that they apply to every project on the machine, including repositories without this setup. They are kept in `user/settings.json`:

| Setting | Effect |
|---|---|
| `"attribution": {"commit": "", "pr": ""}` | Claude Code stops adding its default attribution to commit messages and pull request descriptions, so the agent no longer receives instructions that contradict `commit-authorship.md` |

Apply them once per machine, and again after changing `user/settings.json`:

```bash
user/apply.sh
```

The script deep-merges `user/settings.json` into `~/.claude/settings.json`, keeps every other setting, and writes a timestamped backup before changing anything. It takes effect in running sessions.

## Optional add-ons (`optional/`)

| Add-on | Scope | What it does |
|---|---|---|
| [`client-context/`](optional/client-context/README.md) | One project | Records client messages verbatim in dated logs, keeps a cited summary of the current project state, and makes the agent re-check it before any client-facing output |
| [`notion-mcp/`](optional/notion-mcp/README.md) | The whole machine | Installs a Notion MCP server from its zip and registers it at user scope, so every project can read Notion pages |

## Usage

Requirements: `bash`, `jq` and `sha256sum`.

### As a standalone project

Clone the repository and open it with Claude Code. The settings in `.claude/settings.json` register the hooks and status line.

### In another repository

Copy the files from the branch you need. To keep them out of that repository's history, use the local variants that Claude Code also reads:

```bash
SRC=path/to/AgentSetup
DST=path/to/project

cp -a "$SRC/.claude/rules" "$SRC/.claude/hooks" "$SRC/.claude/statusline.sh" "$DST/.claude/"
cp -a "$SRC/.claude/settings.json" "$DST/.claude/settings.local.json"
cp -a "$SRC/CLAUDE.md" "$DST/CLAUDE.local.md"
```

Then make sure the copied files are ignored, for example in `.git/info/exclude`:

```
.claude/rules/
.claude/hooks/
.claude/statusline.sh
.claude/settings.local.json
.claude/.context-cache/
CLAUDE.local.md
```

If the project already has its own `CLAUDE.md` or `.claude/settings.json`, keep them; the local files are merged with them.

For a client project, also install client context tracking:

```bash
"$SRC/optional/client-context/install.sh" "$DST"
```

## Customising

- **Add a rule:** create `.claude/rules/<name>.md` with a one-line summary, the rule, its rationale and how to apply it, then add it to the list in `CLAUDE.md`.
- **Report language:** the commit and PR report table uses Vietnamese column headers (`Mục | Kết quả`); edit `commit-pr-report-table.md` to change them.
