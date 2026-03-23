<!--
Sync Impact Report:
- Version change: 1.2.0 -> 1.2.1
- Modified principles: none (no renames or removals)
- Added sections: none
- Removed sections: none
- Templates requiring updates:
  - .specify/templates/plan-template.md (✅ checked - Constitution Check section aligns with current principles)
  - .specify/templates/spec-template.md (✅ checked - mandatory sections align)
  - .specify/templates/tasks-template.md (✅ checked - no principle-specific task types missing)
  - .specify/templates/checklist-template.md (✅ checked - generic; no constitution refs)
  - .specify/templates/agent-file-template.md (✅ checked - no outdated agent-specific references)
- Follow-up TODOs: none (all placeholders resolved; no deferrals)
- Bump rationale: PATCH — governance date corrected to 2026-03-22, wording tightened on
  "vague language" audit (no "should" → MUST/SHOULD conversions required; principles
  already use MUST throughout), and validation pass confirmed no bracket tokens remain.
-->

# Church Servants Manager Constitution

## Core Principles

### I. Production Stability & Schema Integrity
As a production application, maintaining the integrity of existing data and behavior is the highest priority.
- Modifications MUST NEVER break the existing Firestore schema or document structure.
- Changes MUST NEVER break or alter existing behavior in production features unless explicitly requested.
- Backward compatibility with existing user data MUST be maintained at all times.

### II. Surgical & Minimal Interventions
Efficiency and stability are achieved through precision.
- All fixes MUST be surgical and minimal in scope.
- Code unrelated to the current task MUST NOT be refactored.
- "Clean up as you go" is restricted to the immediate vicinity of the change to avoid regression risks.

### III. Business Logic Isolation (Cubits Only)
The UI layer MUST remain a pure reflection of state.
- Business logic belongs EXCLUSIVELY in Cubits (or Blocs) — NEVER in widgets.
- Widgets MUST only handle rendering and user interaction events.

### IV. Encapsulated Data Access (Repository Layer)
Data sources MUST be abstracted to ensure portability and testability.
- Firestore access MUST only occur through the Repository layer.
- NEVER access Firestore or Firebase Auth directly from the UI or Cubit layers.

### V. Feature-First Structure
The codebase MUST be organized by vertical feature slices.
- Each feature in `lib/features/` MUST contain its own `data`, `domain`, and `presentation`
  layers to ensure high cohesion and low coupling.

## Technical Constraints

### 1. Immutable & Comparable State
All state classes and data models MUST be immutable and support value-based equality.
- Use `freezed` for models and complex states.
- Use `equatable` for simple state classes where code generation is not desired.

### 2. Dependency Injection (GetIt)
All services, repositories, and BLoCs/Cubits MUST be registered and accessed via `GetIt`.
Registration MUST be manual to maintain explicit control over the dependency graph.

### 3. Flutter & Mobile Deep Architect Rules
All UI implementations MUST adhere to Principal-level Flutter patterns:
- No Layer Violations: Widgets MUST NOT touch Firestore; Cubits MUST NOT touch UI or Navigation.
- No God Widgets (>150 lines) or God Cubits (>200 lines). Break down into modular, testable
  components.
- Zero AI-generated "smells" (e.g., null safety theater, dynamic typing, bad JSON parsing,
  fake async).
- Performance First: `const` everywhere, no `Expanded` outside `Flex`, and tight
  `setState`/`BlocBuilder` bounds.

## Development Workflow

### 1. Fix Traceability
Every bug fix or surgical intervention MUST be documented in the code.
- Add a trailing comment to changed lines or a block comment: `// FIX [ID]: reason`.
- `[ID]` MUST correspond to a task ID or ticket number if available.

### 2. Design Governance
AI-driven implementation is restricted to established patterns.
- If a task requires a design decision (UI/UX or Architecture) not covered by existing
  patterns, it MUST be marked `HUMAN DECISION REQUIRED`.
- Implementation of that specific component MUST be skipped until a human decision is provided.

### 3. Code Generation
After modifying any `freezed` or `json_serializable` annotated files, run:
`dart run build_runner build --delete-conflicting-outputs`

## Governance
This Constitution is the primary authority for all code changes in this repository.
All pull requests and AI-assisted changes MUST be verified against these principles before
merging. Amendments require: (1) a documented rationale, (2) a version bump per semantic
versioning rules below, and (3) propagation of changes to all dependent templates listed in
the Sync Impact Report.

**Versioning Policy**:
- MAJOR: Backward-incompatible governance/principle removals or redefinitions.
- MINOR: New principle or section added, or materially expanded guidance.
- PATCH: Clarifications, wording fixes, typo corrections, non-semantic refinements.

**Version**: 1.2.1 | **Ratified**: 2026-03-18 | **Last Amended**: 2026-03-22
