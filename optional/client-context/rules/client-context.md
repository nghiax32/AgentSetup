# client-context

> Client communication is recorded verbatim in dated logs and summarised in `facts.md`. Never produce client-facing work from a stale or unverified summary.

## Rule

### Files

All client context lives in `.claude/client-context/`, which is excluded from version control:

- `log/YYYY-MM-DD.md`: verbatim client messages, one file per day. Append-only.
- `facts.md`: the current project state derived from the logs by the sync procedure below.
- `.synced`: hashes of the log versions `facts.md` reflects. Written only by `.claude/hooks/client-context-check.sh --mark-synced`.

If `log/` does not exist or is empty, the project has no recorded client context: this rule does not apply beyond recording messages when asked, and no files are created.

### Recording messages

When the user provides client messages and asks for them to be recorded, append them to the log for the date the messages were sent (not today's date, if different), creating the file if needed. Use this format, oldest entry first:

```markdown
## 14:32 · Slack · <sender name and role>
<message text, verbatim>
```

- Keep the text exactly as given, including language, typos and formatting. Do not summarise or translate.
- Information not received in writing (calls, meetings, changes observed directly) is recorded as a dated note: `## 10:00 · call · <who>` followed by what was said.
- Never edit or delete existing log entries.

### Using client context

- **Before any task that depends on client context**, check that `facts.md` is synced. If a `<client-context-stale>` warning is present or the sync state is unknown, run the sync procedure first. A request for such a task counts as the instruction to sync; for a plain question, report that the context is stale and offer to sync.
- **Before producing client-facing output** (reports, estimates, replies, incident write-ups, documentation for the client):
  1. sync as above
  2. list the facts the output relies on, with their dates and sources
  3. ask the user to confirm any fact that is older than the latest change in its area, is listed under Open questions, or describes state that may have changed outside the logs, such as infrastructure, configuration and versions
- Where a fact can be checked against the real system (cluster, config, repository), check it and report any discrepancy instead of choosing one silently.
- Never present an assumption as client-confirmed fact.

### Sync procedure

1. **Find unsynced logs:**
   ```bash
   cd "$CLAUDE_PROJECT_DIR/.claude/client-context" && find log -maxdepth 1 -type f -name '*.md' | sort | xargs -r sha256sum | diff - .synced
   ```
   Lines starting with `<` are new or modified logs; lines starting with `>` only are deleted logs. If `.synced` does not exist, every log is unsynced. If nothing differs and `facts.md` exists, the context is up to date.
2. **Create `facts.md` if missing**, using the template below.
3. **Read every unsynced log in full**, in date order. For a modified log, identify what is new compared with what `facts.md` already cites from it.
4. **Update `facts.md`:**
   - Record only what the logs state. Do not infer, extrapolate or fill gaps.
   - Every fact cites its source: `(since YYYY-MM-DD, log/YYYY-MM-DD.md)`.
   - When a fact changes, keep the old value struck through beneath the new one with its validity period, and add a line to **Change history**. Never silently overwrite a fact.
   - When the logs are ambiguous or contradict each other, or a statement may be tentative ("maybe", "we are considering"), do not record it as fact. Add it to **Open questions** with a short verbatim quote and its source.
   - Write numbers, versions, names and configuration values exactly as the client gave them.
   - Remove nothing except duplicates. If a log was deleted, keep the facts it supported and flag them in **Open questions**.
   - Set the `Last synced` line to today's date and the newest log file.
5. **Mark the logs as synced:** `"$CLAUDE_PROJECT_DIR"/.claude/hooks/client-context-check.sh --mark-synced`
6. **Report** a table `Fact | Before | After | Source` of every added or changed fact, and every open question that needs the user's confirmation, especially any that affect the current task.

`facts.md` template:

```markdown
# Client context

> Current state of the project as communicated by the client. Derived from `log/`. Each fact cites its source log; superseded facts are struck through, not deleted.

Last synced: YYYY-MM-DD (up to log/YYYY-MM-DD.md)

## Infrastructure and environments

## Scope and requirements

## Decisions and agreements

## Deadlines and milestones

## Contacts and roles

## Client preferences and sensitivities

## Open questions

## Change history
```

Example entries:

```markdown
## Infrastructure and environments
- API service: **3 replicas** (since 2026-03-10, log/2026-03-10.md)
  - ~~2 replicas~~ (until 2026-03-09, log/2026-02-02.md)

## Change history
- 2026-03-10: API service scaled from 2 to 3 replicas (log/2026-03-10.md)
```

### Confidentiality

Logs and `facts.md` contain confidential client data. Never commit them, include their contents in commits or PRs, or send them to external services.

## Rationale

Client-facing work built on outdated context damages the client's trust. Verbatim dated logs preserve the source; a synced, cited summary keeps the current state explicit; and the staleness hook makes a forgotten sync visible before it causes harm.

## How to apply

1. Client messages provided for recording go into `log/` verbatim.
2. A `<client-context-stale>` warning means `facts.md` is not reliable until the sync procedure has run.
3. Client-facing output is always preceded by a sync and a list of cited facts.
