# commit-pr-report-table

> Verify the actual state of a commit or PR before reporting it, and present it as a `Mục | Kết quả` table.

## Rule

When checking or reporting a commit or PR, first verify its actual local and remote state, then present it in this format:

| Mục | Kết quả |
|---|---|
| Author | Human author and committer, no co-author; GPG status only if the project signs commits |
| Base | Whether it is on the latest target branch (e.g. `origin/develop`); commits ahead/behind |
| Nội dung | Files changed and +/- lines; confirms the latest edit is included |
| Working tree | Clean, or what remains uncommitted or untracked |
| Lint | Result of the project's lint checks (e.g. isort, whitespace) |
| Test | Number of tests passed, run against exactly this code |

Also report the remote state:

- whether the branch is pushed (`git ls-remote`)
- whether a PR exists (`gh pr list --head <branch>`)

## Rationale

The table gives a complete, verifiable status at a glance. Verifying actual state, rather than relying on recollection, prevents inaccurate reports. For example, a commit can exist even though the command that created it was rejected or interrupted.

## How to apply

1. After any rejected or interrupted command, check `git log`, `git status` and the remote before stating what did or did not happen.
2. Use the table whenever reporting a commit or PR.

Related: `.claude/rules/commit-authorship.md`, `.claude/rules/commit-pr-only-when-asked.md`.
