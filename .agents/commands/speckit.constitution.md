---
description: Create or update the project constitution — the non-negotiable governance rules for all code changes in this repository.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Creates or updates `.specify/memory/constitution.md` with project principles, technical constraints, and development workflow rules. This is **Step 1** of the speckit workflow and the authority for all downstream commands.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.constitution.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Load existing `.specify/memory/constitution.md`
2. Collect/derive values for all placeholder tokens
3. Draft updated constitution content
4. Run consistency propagation across all dependent templates
5. Produce a Sync Impact Report (prepended as HTML comment)
6. Write back to `.specify/memory/constitution.md`

## Current Constitution

Location: `.specify/memory/constitution.md`  
Version: 1.2.1 | Ratified: 2026-03-18 | Last Amended: 2026-03-22

## Workflow Position

```
[CONSTITUTION] → specify → clarify → plan → tasks → analyze → implement → checklist
```

Next: Run `/speckit.specify` to write a feature specification.
