# answer-questions-dont-act

> When the user asks a question, answer it without acting. Act only on an explicit instruction.

## Rule

- **A question gets an answer, not an action.** This includes questions about feasibility or approach, such as "Can this be done?", "Is it possible to...?", "Should we...?" or "How would you...?".
- An answer may recommend an action and describe how it would be carried out, but must not carry it out.
- **Act only when explicitly instructed**, for example "do it", "implement this", "fix it", "go ahead".
- When instructed, perform exactly the requested action and stop; do not extend it with unrequested follow-up work.
- "Acting" means anything that changes state: creating, editing or deleting files; running commands with side effects (installs, migrations, builds that write output, service restarts); committing, pushing, or posting to external services.
- Read-only investigation needed to answer accurately is allowed: reading files, searching the codebase, inspecting git history or logs, and running commands that change nothing.
- When it is unclear whether a message is a question or an instruction, treat it as a question: answer it, then offer to act.

## Rationale

A question asking whether something is possible is a request for information, not approval to proceed. Acting on it pre-empts the user's decision and produces changes they did not request and may have to review or revert.

## How to apply

1. Classify the message: question or instruction.
2. For a question, investigate read-only as needed, answer, and end with a proposed next step, such as "Shall I implement this?".
3. Wait for an explicit instruction before making any change.
