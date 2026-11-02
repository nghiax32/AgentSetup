# Client context tracking (optional)

For client projects only. Keeps the client's own words as the source of truth, so that reports and replies are never built on outdated context, such as infrastructure the client has since changed.

```
.claude/client-context/        # in the project, never committed
├── log/2026-03-10.md          # verbatim client messages, one file per day, append-only
├── facts.md                   # current project state, each fact citing its source log
└── .synced                    # hashes of the logs facts.md reflects
```

1. Paste client messages and ask the agent to record them; they are appended verbatim to the log for the day they were sent.
2. When logs change, the hook flags `facts.md` as stale until the agent re-syncs it. Changed facts keep their old value struck through, with a change history.
3. Before writing anything for the client, the agent syncs, lists the facts it relies on with their sources, and asks you to confirm any that may be out of date.

The rule and hook do nothing in a project without client logs.

## Install

```bash
path/to/AgentSetup/optional/client-context/install.sh path/to/project
```

The script:

| Step | Target in the project |
|---|---|
| Copies the rule and the staleness hook | `.claude/rules/client-context.md`, `.claude/hooks/client-context-check.sh` |
| Registers the hook (`UserPromptSubmit`) | `.claude/settings.local.json` |
| Adds the rule and the `facts.md` import | `CLAUDE.local.md` |
| Keeps client data and these files out of git | `.git/info/exclude` |

It is safe to run again, for example after updating this repository: files are refreshed and nothing is added twice.

## Contents

- `rules/client-context.md`: how to record messages, when to sync, the sync procedure and the `facts.md` template
- `hooks/client-context-check.sh`: warns when logs changed since the last sync; `--mark-synced` records the synced state
- `install.sh`: the installer above
