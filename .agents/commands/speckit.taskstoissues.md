---
description: Convert tasks.md entries into actionable, dependency-ordered Jira issues for the active feature.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What This Does

Reads `tasks.md` for the active feature and creates Jira issues via the Atlassian MCP tools. Each task becomes a Jira issue with description, dependencies, and phase context.

## Execution

Read and follow the full instructions in `.claude/commands/speckit.taskstoissues.md` for the general approach, but adapted for **Jira** (not GitHub Issues) using the available Atlassian MCP tools.

Key steps:
1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`
2. Load `tasks.md` and extract all tasks with their IDs, descriptions, phases, and dependencies
3. Use `mcp__atlassian__invoke_tool` with `create_jira_issue` to create one issue per task
4. Preserve task ordering and dependency relationships in issue descriptions
5. Report all created issue URLs

## Notes

- This project uses **Jira** via Atlassian MCP (not GitHub Issues)
- Use `get_jira_projects` to find the correct project before creating issues
- Group issues by phase in the description for clarity
- Only create issues for tasks not already tracked

## Workflow Position

Run after `/speckit.tasks` has produced a complete `tasks.md`.
