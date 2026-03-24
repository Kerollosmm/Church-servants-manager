---
description: Identify and resolve up to 5 critical ambiguities in the active feature spec before planning begins.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Scans the current `spec.md` for ambiguities across functional scope, data model, UX flows, non-functional requirements, integrations, and edge cases. Asks up to 5 targeted questions (one at a time) and writes accepted answers back into the spec. This is **Step 3** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.clarify.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly`
2. Load the active `spec.md` and scan for ambiguities
3. Ask up to 5 questions (one at a time, with recommended answers)
4. Write accepted answers back into `spec.md` under a `## Clarifications / Session YYYY-MM-DD` section
5. Report coverage summary and suggest next step

## Workflow Position

```
constitution → specify → [CLARIFY] → plan → tasks → analyze → implement → checklist
```

Next: Run `/speckit.plan` to generate the implementation plan.
