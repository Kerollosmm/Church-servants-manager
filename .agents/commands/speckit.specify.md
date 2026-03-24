---
description: Create or update a feature specification using the spec template. Captures requirements, user stories, acceptance criteria, and edge cases for a new feature.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Runs the speckit `speckit.specify` workflow to create a `spec.md` for a new feature in the `specs/` directory. This is **Step 2** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.specify.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/setup-plan.ps1 -Json` to get paths
2. Load `.specify/memory/constitution.md` for constraints
3. Load `.specify/templates/spec-template.md` as the output structure
4. Interview the user (up to 5 targeted questions) to gather requirements
5. Write the completed `spec.md` to the feature directory

## Workflow Position

```
constitution → [SPECIFY] → clarify → plan → tasks → analyze → implement → checklist
```

Next: Run `/speckit.clarify` to refine the spec, or `/speckit.plan` to proceed directly.
