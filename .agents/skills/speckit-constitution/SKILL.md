---
name: "speckit-constitution"
description: "Create or update project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
 author: "github-spec-kit"
 source: "templates/commands/constitution.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider user input before proceeding (if not empty).

## Outline

You are updating project constitution at `.specify/memory/constitution.md`. This file is TEMPLATE containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to () collect/derive concrete values, (b) fill template precisely, and (c) propagate any amendments across dependent artifacts.

**Note**: If `.specify/memory/constitution.md` does not exist yet, it should have been initialized from `.specify/templates/constitution-template.md` during project setup. If it's missing, copy template first.

Follow this execution flow:

1. Load existing constitution at `.specify/memory/constitution.md`.
 - Identify every placeholder token of form `[ALL_CAPS_IDENTIFIER]`.
 **IMPORTANT**: user might require less or more principles than ones used in template. If number is specified, respect that - follow general template. You will update doc accordingly.

2. Collect/derive values for placeholders:
 - If user input (conversation) supplies value, use it.
 - Otherwise infer from existing repo context (README, docs, prior constitution versions if embedded).
 - For governance dates: `RATIFICATION_DATE` is original adoption date (if unknown ask or mark TODO), `LAST_AMENDED_DATE` is today if changes are made, otherwise keep previous.
 - `CONSTITUTION_VERSION` must increment according to semantic versioning rules:
 - MAJOR: Backward incompatible governance/principle removals or redefinitions.
 - MINOR: New principle/section added or materially expanded guidance.
 - PATCH: Clarifications, wording, typo fixes, non-semantic refinements.
 - If version bump type ambiguous, propose reasoning before finalizing.

3. Draft updated constitution content:
 - Replace every placeholder with concrete text (no bracketed tokens left except intentionally retained template slots that project has chosen not to define yet—explicitly justify any left).
 - Preserve heading hierarchy and comments can be removed once replaced unless they still add clarifying guidance.
 - Ensure each Principle section: succinct name line, paragraph (or bullet list) capturing non‑negotiable rules, explicit rationale if not obvious.
 - Ensure Governance section lists amendment procedure, versioning policy, and compliance review expectations.

4. Consistency propagation checklist (convert prior checklist into active validations):
 - Read `.specify/templates/plan-template.md` and ensure any "Constitution Check" or rules align with updated principles.
 - Read `.specify/templates/spec-template.md` for scope/requirements alignment—update if constitution adds/removes mandatory sections or constraints.
 - Read `.specify/templates/tasks-template.md` and ensure task categorization reflects new or removed principle-driven task types (e.g., observability, versioning, testing discipline).
 - Read each command file in `.specify/templates/commands/*.md` (including this one) to verify no outdated references (agent-specific names, e.g., CLAUDE) remain when generic guidance is required.
 - Read any runtime guidance docs (e.g., `README.md`, `docs/quickstart.md`, or agent-specific guidance files if present). Update references to principles changed.

5. Produce Sync Impact Report (prepend as HTML comment at top of constitution file after update):
 - Version change: old → new
 - List of modified principles (old title → new title if renamed)
 - Added sections
 - Removed sections
 - Templates requiring updates (✅ updated / ⚠ pending) with file paths
 - Follow-up TODOs if any placeholders intentionally deferred.

6. Validation before final output:
 - No remaining unexplained bracket tokens.
 - Version line matches report.
 - Dates ISO format YYYY-MM-DD.
 - Principles are declarative, testable, and free of vague language ("should" → replace with MUST/SHOULD rationale where appropriate).

7. Write completed constitution back to `.specify/memory/constitution.md` (overwrite).

8. Output final summary to user with:
 - New version and bump rationale.
 - Any files flagged for manual follow-up.
 - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z (principle additions + governance update)`).

Formatting & Style Requirements:

- Use Markdown headings exactly as in template (do not demote/promote levels).
- Wrap long rationale lines to keep readability (<100 chars ideally) but do not hard enforce with awkward breaks.
- Keep single blank line between sections.
- Avoid trailing whitespace.

If user supplies partial updates (e.g., only one principle revision), still perform validation and version decision steps.

If critical info missing (e.g., ratification date truly unknown), insert `TODO(<FIELD_NAME>): explanation` and include in Sync Impact Report under deferred items.

Do not create new template; always operate on existing `.specify/memory/constitution.md` file.
