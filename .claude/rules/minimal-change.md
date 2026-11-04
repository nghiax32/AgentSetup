# minimal-change

> Change only what the request needs, and report anything else worth attention. This rule limits what you change, not what you notice or report.

## Rule

### What to change

- **Scope every edit to the request.** Change only the lines needed to do what was asked. Do not, unless requested:
  - reword, reformat, reorder or rename existing code or text
  - add comments, docstrings, type hints, error handling, logging or tests
  - refactor, extract helpers or "clean up" nearby code
  - add sections, examples or notes to documentation
- **Preserve the author's style.** In code and documents, keep the existing structure, wording, tone and conventions, even where you would write it differently.
- **Necessary side changes are allowed, and stated.** When the requested change cannot work without touching something else (an import, a caller, a reference to a renamed file), make that change and name it in the report.
- **The user can widen the scope.** When the request says so (for example "fix whatever else you find"), the reported items are part of the request.

### What to report

Noticing problems outside the request is valuable; keep looking, and report what you find without fixing it:

- **Defects** (a bug, a security issue, a risk of data loss, documentation that contradicts the code): at the **top** of the reply, each with its location and consequence.
- **Improvements** (clarity, style, structure): at the **end** of the reply under "Đề xuất (chưa làm)", a few lines at most, only items worth the user's time.

## Rationale

Every line in a diff is a line the user has to review. Unrequested improvements hide the requested change among unrelated edits, can change behaviour nobody asked to change, and override choices the author made on purpose. Reporting instead of fixing keeps the diff exact while keeping the findings, and puts the decision with the user.

## How to apply

1. Before editing, identify the smallest change that does what was asked.
2. After editing, read the diff (`git diff`, or the changed sections for files outside git). For each changed line, check that it serves the request or a stated necessary side change; revert any line that does not.
3. In the report:
   - defects first, if any
   - then the requested change and any necessary side changes
   - then "Đề xuất (chưa làm)", if any

Related: `.claude/rules/answer-questions-dont-act.md`.
