---
description: Execute the implementation plan phase-by-phase, following the tasks defined in tasks.md.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Reads `tasks.md` and executes all tasks phase-by-phase (Setup → Tests → Core → Integration → Polish). Tracks progress by marking tasks `[X]` in `tasks.md` as they complete. This is **Step 7** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.implement.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`
2. Check all checklists in `checklists/` — prompt before proceeding if any are incomplete
3. Load `tasks.md`, `plan.md`, and all available design artifacts
4. Verify/create `.gitignore` and other ignore files as needed
5. Execute tasks phase-by-phase; respect `[P]` parallel markers and dependencies
6. Mark each completed task `[X]` in `tasks.md`
7. Report progress after each phase; halt on non-parallel failures

## Important Rules

- **TDD approach**: Execute test tasks before their corresponding implementation tasks
- **Sequential files**: Tasks affecting the same file must run sequentially
- **Phase gates**: Complete each phase before moving to the next
- **Constitution compliance**: All code MUST follow the rules in `.specify/memory/constitution.md`
- This project uses Flutter/Dart — follow the architecture rules in `AGENTS.md`

## Workflow Position

```
constitution → specify → clarify → plan → tasks → analyze → [IMPLEMENT] → checklist
```

Next: Run `/speckit.checklist` to validate quality gates before merging.
