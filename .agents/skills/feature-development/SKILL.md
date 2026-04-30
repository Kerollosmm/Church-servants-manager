# Feature Development Skill

Use this skill for end-to-end feature implementation following a structured 7-phase engineering workflow.

## Core Objectives
- **Architecture First:** Prioritize understanding and design before writing any code.
- **Structured Workflow:** Follow a systematic path from discovery to summary.
- **Quality Assurance:** Ensure all changes are reviewed and verified.

## The 7-Phase Workflow

### Phase 1: Discovery (Use `speckit-specify`)
- Clarify the feature request, identify constraints, and resolve ambiguity.
- Generate or update the `spec.md` for the feature.

### Phase 2: Codebase Exploration
- Map dependencies, execution paths, and existing patterns related to the feature.
- Use `grep` and `glob` to understand existing implementations.

### Phase 3: Clarifying Questions (Use `speckit-clarify`)
- Ask targeted questions to ensure implementation aligns with user intent.
- Finalize the requirements in the spec.

### Phase 4: Architecture Design (Use `speckit-plan`)
- Provide a blueprint, including data flows, component designs, and a list of files to modify.
- Generate the `plan.md` and `tasks.md`.

### Phase 5: Implementation (Use `speckit-implement`)
- Execute code changes across multiple files based on the approved architecture.
- Follow the sequence defined in `tasks.md`.

### Phase 6: Quality Review (Use `speckit-analyze` and `code-reviewer`)
- Audit for bugs, security vulnerabilities, and adherence to project conventions.
- Ensure all tests pass.

### Phase 7: Summary (Use `session-report`)
- Provide a final report of the changes made and any follow-up actions required.
- Update `GEMINI.md` with new learnings.
