# Memory

## Me
ChurchServers Management System (CSMS) Architect Agent. I build/maintain the CSMS Flutter/Firebase application, following offline-first and Spark-plan constraints.

## Current State (Jul 21, 2026)
- **Branch:** `fix/csms-critical-and-important-issues`
- **Phase:** Feature `030-ultra-review-remediation` SpecKit plan & design artifacts created.
- **Milestone:** Conducted CSMS Ultra Code Review audit. Identified 4 Critical and 4 Important findings. Generated full SpecKit suite (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `tasks.md`).
- **Next:** Execute implementation plan phases 1 through 5.

## Gemini CLI Shortcuts
| Path Alias | Location | Purpose |
|------------|----------|---------|
| `lib` | `lib/` | Main source code |
| `feat` | `lib/features/` | Feature-based modules |
| `core` | `lib/core/` | Architecture & DI |
| `mem` | `memory/` | Full knowledge base |

## People
| Who | Role |
|-----|------|
| **Admin** | System Administrators |
| **Servant** | Church Servants/Helpers |
| **Teacher** | Group Leaders/Teachers |
→ Profiles: `mem/people/` (or `memory/people/`)

## Terms
| Term | Meaning |
|------|---------|
| CSMS | ChurchServers Management System |
| Spark Plan | Firebase Free Tier (No Cloud Functions) |
| RBAC | Role-Based Access Control |
→ Full glossary: `mem/glossary.md`

## Projects
| Name | What |
|------|------|
| **CSMS** | ChurchServers Management System |
→ Details: `mem/projects/`

## Memory Protocol (MANDATORY)
- **First Turn Action**: You **MUST** run `view_file` on `CLAUDE.md` and check relevant `memory/` files at the very beginning of the session to establish state, active workstream, and preferences.
- **Ongoing Updates**: Update the `memory/` files and `CLAUDE.md` whenever you complete a task, introduce new classes, modify APIs, or shift architecture.
- **Final Sync**: Before concluding a work stream, ensure `tasks.md`, `CLAUDE.md`, and any related memory docs are updated. Run `/update-memory` to verify.
- **Decode Entities**: If you encounter a new name, project term, or class not documented in `memory/`, document it.

## Preferences
- Offline-first is non-negotiable.
- Minimize Firestore reads (Spark plan limits).
- Use Hive as SSOT for UI.
- No Cloud Functions.
- Use Custom Claims (if possible, fallback to Firestore rules).
- Caveman mode: full.
- Prioritize using specialized Flutter and Dart agent skills (Clean Architecture, BLoC, security, optimization) and advanced capabilities (superpowers) for all codebase operations.


