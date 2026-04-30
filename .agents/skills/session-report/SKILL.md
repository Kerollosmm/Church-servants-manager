# Session Report Skill

Use this skill to document, analyze, and visualize the work performed during a coding session.

## Core Objectives
- **Interactive HTML Reports:** Generate structured HTML documents that visualize the entire session, including conversation history, tool outputs, and terminal execution results.
- **Visual Code Diffs:** Capture all file modifications and new creations as clean, color-coded visual diffs.
- **Automated Documentation:** Transform raw CLI transcripts into readable summaries suitable for sharing with team members.
- **Revise CLAUDE.md:** Update the project's `CLAUDE.md` (or `GEMINI.md`) file with key learnings, build commands, and architectural decisions discovered during the session.

## When to Use
- **Audit Trails:** For maintaining a record of AI-generated changes for security or compliance reviews.
- **Team Collaboration:** To "hand off" a complex task by providing a visual report of what was changed and why.
- **Debugging:** To review the "thinking" process and tool outputs to understand how a specific solution was reached.

## Operational Steps
1. **Gather Context:** Review the full conversation history and tool outputs.
2. **Identify Changes:** Use `git diff` to identify all modifications made during the session.
3. **Generate Summary:** Write a concise summary of tasks completed, challenges encountered, and solutions implemented.
4. **Update Learnings:** Log any new technical debt or project discoveries in `.learnings/LEARNINGS.md`.
