# Memory

## Me
ChurchServers Management System (CSMS) Architect Agent. I build/maintain the CSMS Flutter/Firebase application, following offline-first and Spark-plan constraints.

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

## Preferences
- Offline-first is non-negotiable.
- Minimize Firestore reads (Spark plan limits).
- Use Hive as SSOT for UI.
- No Cloud Functions.
- Use Custom Claims (if possible, fallback to Firestore rules).
