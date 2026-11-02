# commit-pr-only-when-asked

> Perform commit and PR operations only when specifically requested, and commit only the files the task changed. Never commit `.gitignore` unless specifically requested.

## Rule

### When to act

- **Commit and PR operations require a specific request.** These operations are:
  - `git commit` and `git push`
  - creating, editing, merging or closing a pull request
  - posting PR comments or reviews, and resolving review threads
- **Each step requires its own request.** A request to commit does not authorise a push, and a request to push does not authorise opening a PR.
- Completing a task does not imply committing it. Writing files, running tests and reporting results are the deliverable.

### What to commit

- Stage files explicitly by path. Do not use `git add -A`, `git add .` or `git commit -a`.
- **Never stage or commit `.gitignore`** (at any level of the repository) unless the user specifically requests it. Treat local modifications to `.gitignore` as the user's private configuration, not as part of the current task, and do not revert, restore or stash them.

### How to run git

- Never guess at a git command when the correct one is known, and never chain alternative commit commands with `||`.
- Write commit messages out in full. Do not reuse an existing message or authorship with `-C` or `-c`.

## Rationale

Every commit, push and PR action on a shared repository is visible to others and has consequences the user has not delegated. Bulk staging picks up unrelated files; in particular, the user edits `.gitignore` locally to hide personal files such as agent setup files, and committing it would leak that private configuration into the project history. Fallback chains are unsafe: in `git commit -C ORIG_HEAD || git commit -m "..."`, the first command can succeed and silently take another developer's authorship and message.

## How to apply

1. After completing the requested work, report the result and ask whether to commit, push or open a PR.
2. When a commit is requested:
   - check `git status` and stage only the files the task changed, leaving `.gitignore` out
   - if `.gitignore` was staged, unstage it with `git restore --staged .gitignore`
   - follow `.claude/rules/commit-authorship.md`
3. In commit and PR reports, do not list `.gitignore` as part of the change.
4. To undo an unrequested commit while keeping the changes in the working tree, run `git reset --soft HEAD~1 && git reset`.
