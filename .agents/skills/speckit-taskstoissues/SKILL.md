---
name: "speckit-taskstoissues"
description: "Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/taskstoissues.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks` from the repository root. This script emits JSON; parse that JSON output to extract the `FEATURE_DIR` value (string) and `AVAILABLE_DOCS` value (object). Convert any relative paths in `FEATURE_DIR` and each entry of `AVAILABLE_DOCS` to absolute paths using the repository root as the base. For single quotes in args in PowerShell, use doubled single quotes: e.g. `'I''m Groot'` or double quotes: `"I'm Groot"`.
1. From the executed script, extract the path to **tasks** via `AVAILABLE_DOCS["tasks"]`. The `-IncludeTasks` flag ensures the tasks path is included in the `AVAILABLE_DOCS` object. Downstream code should read `AVAILABLE_DOCS["tasks"]` to locate the tasks file.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. Validate the remote is GitHub:
   - Accepted HTTPS form: `https://github.com/<owner>/<repo>.git` (or without `.git`)
   - Accepted SSH form: `git@github.com:<owner>/<repo>.git` (or without `.git`)
   - Parse the URL using regex: `^https://github\.com/[\w.-]+/[\w.-]+(\.git)?$` for HTTPS or `^git@github\.com:[\w.-]+/[\w.-]+(\.git)?$` for SSH
   - If the host is not `github.com`, abort with an error: "Remote is not a GitHub repository. Expected github.com in the remote URL."
   - Enterprise GitHub hosts are NOT accepted unless explicitly configured.

1. Resolve dependencies:
   - Extract dependencies for each task (e.g., via explicit "depends on" markers, keyword parsing, or review of design artifacts).
   - Compute an ordering (e.g., topological sort or phase-based dependency resolution) so issues are created in the correct sequence.
1. For each task in the resolved list, explicitly map task fields to issue fields and call the MCP tool:
   - Use the task name/summary for the issue **Title**.
   - Compose the **Body** from the task description, acceptance criteria, and links to relevant artifacts from `AVAILABLE_DOCS`.
   - Represent relationships generated from dependency resolution using issue links ("depends on" or "blocked by"), task lists, or standardized labels.
   - Apply labels like "task" and "speckit-generated".
   - Invoke the GitHub MCP server via its `create_issue` tool (or function) passing the repository derived from the Git remote URL, the title, body, labels array, and any assignees or milestone if present in the task metadata.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL
