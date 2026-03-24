---
description: Break the implementation plan into a structured, dependency-ordered task list ready for execution.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Reads `plan.md` (and optionally `research.md`, `data-model.md`) and produces a `tasks.md` with phase-grouped, dependency-ordered tasks using IDs like `T001`. This is **Step 5** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.tasks.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json` to get FEATURE_DIR and available docs
2. Load `plan.md`, `spec.md`, and any available design artifacts
3. Load `.specify/templates/tasks-template.md` as the output structure
4. Generate tasks grouped by phase (Setup, Tests, Core, Integration, Polish)
5. Mark parallel tasks with `[P]`, set dependencies explicitly
6. Write `tasks.md` to the feature directory

## Task Format

```markdown
- [ ] T001 [P] Short description of what to do
  - Files: lib/features/foo/data/models/foo_model.dart
  - Depends: none
```

## Workflow Position

```
constitution → specify → clarify → plan → [TASKS] → analyze → implement → checklist
```

Next: Run `/speckit.analyze` to validate coverage, or `/speckit.implement` to start building.
