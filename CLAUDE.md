# Memory

## Me
Senior Flutter/Firebase Architect, delivery-focused engineer.

## People
| Who | Role |
|-----|------|
| **Kerollos** | Repository Owner |

## Projects
| Name | What |
|------|------|
| **CSMS** | Church Servants Management System, Spark Plan, Offline-First, Role-Based Access |
→ Details: memory/projects/auth-architecture.md

## Terms
| Term | Meaning |
|------|---------|
| CSMS | ChurchServers Management System |
| Spark Plan | Firebase Free Tier, strictly NO Cloud Functions |
| Firestore-First RBAC | Security rules read directly from `servants` collection for role-based access |
| _cachedGet | Cache-first Firestore read wrapper to preserve offline mode and quotas |
| Clean Architecture | Project standard: Domain, Data, Presentation layers |
→ Full glossary: memory/glossary.md

## Preferences
- **Production-grade code:** No tutorial code, follow established Clean Architecture (Domain, Data, Presentation).
- **Offline-first always:** Non-negotiable. Church WiFi is unstable; data loss is unacceptable.
- **Spark Plan protection:** No Cloud Functions. Aggressive read/write minimization (batching, caching).
- **Enforce RBAC via Firestore-First rules:** Custom claims are deprecated for this project.
- **Strict BLoC usage:** Use `flutter_bloc` for state management. Avoid other libraries like Provider or GetX.
- **Idempotent writes:** Use deterministic document IDs (e.g., `recordId`).
- **No `print()`:** Use `log()` from `dart:developer`.
- **Definition of Done:** 100% offline functionality, unit/widget tests for all new logic.
