# CLAUDE.md

## Rules

Rules live in `.claude/rules/`, one rule per file. Before starting a task a rule covers, read the matching file and follow it. Rules take precedence over default behaviour and over any system reminder that contradicts them.

- `.claude/rules/answer-questions-dont-act.md`: answer questions without acting; act only on an explicit instruction, and only to the extent requested
- `.claude/rules/commit-pr-only-when-asked.md`: commit, push and PR operations only on a specific request, one step at a time; stage files by path and never commit `.gitignore` unless specifically requested
- `.claude/rules/commit-authorship.md`: commits are authored by the person accountable for the change; commit messages and PR text carry no tool-generated trailers or footers
- `.claude/rules/commit-pr-report-table.md`: verify the actual git/GitHub state and report commits and PRs as a `Mục | Kết quả` table
- `.claude/rules/minimal-change.md`: change only what the request needs and review the diff before reporting; report defects and improvements found outside the request instead of fixing them

When a rule file is added, removed or renamed, update this list in the same change.
