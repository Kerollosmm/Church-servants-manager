# Commit Commands Skill

Use this skill to automate Git workflows including intelligent commit message generation, branch management, and pull request creation.

## Core Features
- **Conventional Commits:** Automatically categorize changes (e.g., `feat:`, `fix:`, `docs:`, `refactor:`) and use appropriate emojis.
- **Pre-commit Validation:** Run project-specific checks (linting, formatting, or builds) before committing.
- **Atomic Commit Suggestions:** Suggest splitting unrelated logical changes into separate, smaller commits.
- **Context Awareness:** Ensure generated messages match the project's existing style and conventions by analyzing `git diff` and recent history.

## Key Commands
- **Commit:** Stage changes and create a commit with an AI-generated message following Conventional Commits.
- **Commit-Push-PR:** Commit, push the branch to remote, and create a pull request in one step.
- **Amend:** Amend the last commit with current changes and update the message if needed.
- **Stash:** Intelligently stash changes with a descriptive name based on the diff content.

## Operational Protocol
1. **Analyze Diff:** Use `git diff` to understand all changes.
2. **Run Checks:** Execute `dart analyze` and `dart format` (for Flutter/Dart projects).
3. **Generate Message:** Draft a concise, "why-focused" message.
4. **Finalize:** Add the mandatory attribution suffix:
   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   Co-Authored-By: Claude <noreply@anthropic.com>
