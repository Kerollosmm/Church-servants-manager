---
description: Generate or validate quality-gate checklists (UX, security, testing, performance) before implementation or merge.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Creates structured quality-gate checklists in `specs/<feature>/checklists/` covering UX, security, testing, and performance criteria derived from the spec and plan. This is **Step 8** of the speckit workflow. Also used by `/speckit.implement` to gate execution.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.checklist.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json` to get FEATURE_DIR
2. Load `spec.md`, `plan.md`, and optionally `tasks.md`
3. Load `.specify/templates/checklist-template.md` as the structure
4. Generate domain-specific checklists (UX, security, test coverage, performance)
5. Write checklist files to `specs/<feature>/checklists/`

## Checklist Format

```markdown
- [ ] Item description
- [X] Completed item
```

## Workflow Position

```
constitution → specify → clarify → plan → tasks → analyze → implement → [CHECKLIST]
```

All checklist items must be `[X]` before `/speckit.implement` will auto-proceed.
