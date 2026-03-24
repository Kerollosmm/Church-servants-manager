---
description: Generate the implementation plan, data model, and research artifacts for the active feature spec.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Produces `plan.md`, `research.md`, and `data-model.md` for the active feature. Validates against the project constitution and resolves all technical unknowns. This is **Step 4** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.plan.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/setup-plan.ps1 -Json` — get FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH
2. Load `spec.md` and `.specify/memory/constitution.md`
3. Phase 0: Resolve NEEDS CLARIFICATION items → write `research.md`
4. Phase 1: Extract entities → write `data-model.md`; define contracts if applicable
5. Run `.specify/scripts/powershell/update-agent-context.ps1` to sync AGENTS.md
6. Fill the plan template and write `plan.md`

## Workflow Position

```
constitution → specify → clarify → [PLAN] → tasks → analyze → implement → checklist
```

Next: Run `/speckit.tasks` to break the plan into executable tasks.
