---
description: Non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md. Read-only — produces a structured report only.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Validates consistency, coverage, and constitution compliance across `spec.md`, `plan.md`, and `tasks.md`. **Does NOT modify any files.** Produces a structured report with severity-ranked findings. This is **Step 6** of the speckit workflow.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.analyze.md`, substituting `$ARGUMENTS` with the user input above.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`
2. Load spec, plan, tasks, and constitution
3. Run detection passes: Duplication, Ambiguity, Underspecification, Constitution Alignment, Coverage Gaps, Inconsistency
4. Assign severity: CRITICAL / HIGH / MEDIUM / LOW
5. Output a findings table (max 50 rows) + coverage summary + metrics
6. Offer remediation suggestions (does NOT apply them automatically)

## Severity Guide

- **CRITICAL**: Constitution violation, zero-coverage requirement, or missing core artifact
- **HIGH**: Conflicting requirements, ambiguous security/perf attribute
- **MEDIUM**: Terminology drift, missing NFR task coverage
- **LOW**: Wording/style improvements

## Workflow Position

```
constitution → specify → clarify → plan → tasks → [ANALYZE] → implement → checklist
```

Next: Fix any CRITICAL issues, then run `/speckit.implement`.
