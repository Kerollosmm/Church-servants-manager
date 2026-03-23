# Feature Specification: Full Code Review

**Feature Branch**: `001-full-code-review`  
**Created**: 2026-03-18  
**Status**: Draft  
**Input**: User description: "Perform a full CodeRabbit-level code review of the entire repository and produce a complete bug report and fix plan. Review scope: 1. Bugs & crashes — null errors, unhandled futures, memory leaks, race conditions, unmounted widget operations 2. Architecture violations — layering violations, business logic in widgets, Firestore leaking into presentation, missing abstractions 3. State management issues — dead states/events, missing Equatable, setState misuse, BLoCs never closed, state mutation 4. Performance problems — unnecessary rebuilds, N+1 Firestore queries, missing pagination, futures recreated on rebuild Output: a complete report saved to docs/review/BUG_REPORT.md with every issue categorized by severity (P0/P1/P2), file reference, description, and fix approach. Then produce a prioritized fix plan organized as Sprint 1 (critical), Sprint 2 (high), Sprint 3 (medium). Do NOT fix anything yet. Review and report only."

## Clarifications

### Session 2026-03-18
- Q: Which review engine/mechanism should be used? → A: Detailed LLM-based deep reasoning for line-by-line analysis.
- Q: Which files should be included in the review? → A: All files and folders inside the `lib/` directory only.
- Q: How should the review findings be formatted? → A: Annotated copies of source files (original code + inline "deepthink" comments) saved to `docs/review/`.
- Q: How should the review reports be organized? → A: One report per major feature folder (e.g., `docs/review/features/auth_report.md`).
- Q: Should the fix plan be unified or separate per feature? → A: Unified master fix plan (Sprint 1-3) for the entire project.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Produce Feature-Specific Review Reports (Priority: P1)

As a maintainer, I want the review organized by feature folders so that I can easily find all issues and deepthink commentary related to a specific part of the application (e.g., authentication, attendance).

**Why this priority**: Organization by feature aligns with the project's feature-first architecture and makes the massive output manageable.

**Independent Test**: Verify that `docs/review/features/` contains separate report files for each major subdirectory found in `lib/features/`.

---

### User Story 2 - Annotated Source Deepthink (Priority: P1)

As a developer, I want to see "deepthink" comments directly alongside the original code in generated review files, so that I can understand the reasoning for every line and identified bug in context.

**Why this priority**: Line-by-line analysis is the primary user requirement for this high-depth review.

**Independent Test**: Open an annotated file in `docs/review/` and verify it contains the original source code with injected logic analysis and issue annotations.

---

### User Story 3 - Unified Remediation Roadmap (Priority: P1)

As a project owner, I want a single, unified roadmap for Sprint 1, 2, and 3, so that I can prioritize the most critical stability and architectural fixes across the entire app.

**Why this priority**: Essential for turning a massive review into a manageable implementation plan.

**Independent Test**: Verify the existence of `docs/review/MASTER_FIX_PLAN.md` containing a consolidated schedule for all identified issues.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST perform a line-by-line deep-reasoning review of all files within the `lib/` directory.
- **FR-002**: System MUST generate annotated copies of source files containing original code + "deepthink" commentary in `docs/review/annotated/`.
- **FR-003**: System MUST exclude generated files (`*.g.dart`, `*.freezed.dart`) from the review scope.
- **FR-004**: System MUST organize review findings into separate report files corresponding to major feature directories in `lib/features/`.
- **FR-005**: System MUST identify and categorize issues by severity (P0: Critical/Bug, P1: Architectural Violation, P2: Technical Debt/Performance).
- **FR-006**: System MUST consolidate all identified issues into a single `MASTER_FIX_PLAN.md` organized into three sprints.
- **FR-007**: System MUST NOT modify any files within the `lib/` directory (strictly read-only review).

### Key Entities

- **Deepthink Annotation**: Contextual commentary for a specific block or line of code, analyzing logic, intent, or potential failure points.
- **Feature Report**: A summary of findings for a specific vertical slice of the application.
- **Master Roadmap**: A consolidated timeline prioritizing all discovered technical debt and bugs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Generation of `docs/review/MASTER_FIX_PLAN.md` containing all P0/P1/P2 issues.
- **SC-002**: 100% of human-written `.dart` files in `lib/` have corresponding annotated output in `docs/review/`.
- **SC-003**: 0 files outside `docs/` or `specs/` are modified.
- **SC-004**: All reports are categorized into vertical slices matching `lib/features/` subdirectories.

### Edge Cases

- **Large Files**: For files exceeding context limits, the system MUST process them in sequential chunks while maintaining architectural context.
- **Ambiguous Patterns**: If a code pattern is ambiguous, the system MUST mark it `HUMAN DECISION REQUIRED` in the annotation.
