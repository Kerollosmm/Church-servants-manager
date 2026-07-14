# CSMS Architecture

**Codename:** CSMS
**Status:** Active, Fully Refactored (Jul 2026)

## Core Architecture
- **Clean Architecture:** Separated into `data`, `domain`, and `presentation` layers.
- **Identity vs Profile:** Firebase handles Auth (Identity), Firestore handles metadata (Profile).
- **RBAC:** Firestore-First RBAC. Rules perform direct lookups against the `servants` collection. (Custom claims deprecated due to Spark Plan constraints).
- **Spark Plan Constraints:** No Cloud Functions. All logic is client-side. Strict optimization of Firestore reads/writes.
- **Offline-First:** Hive local storage cache (SSOT). All repositories use `_cachedGet` (Source.cache → Source.server).

## Authentication System
- **Provider:** `FirebaseIdentityProvider`.
- **Repository:** `FirebaseAuthRepository` — injected `FirebaseFirestore` (not `FirebaseFirestore.instance`), fetches user using Source.serverAndServer, caches in `AuthUserLocalStore`.
- **Bloc:** `AuthBloc` — guards session listener against race conditions; logs silent catch blocks; fires `setAuthenticatedUser` on every transition.
- **Security:** `AuthFreshnessPolicy` (15-min write window).
- **UI States:** `AuthAuthenticated`, `AuthDegraded` (read-only/offline), `AuthArchived`, `AuthRoleUpdated`, `AuthRoleRefreshing`.
- **Gating:** `AdminGate` ensures administrative access with session freshness.

## Sync System (Outbox Pattern)
- **Engine:** `SyncService` — per-user Hive boxes (`sync_queue_$userId`), FIFO processing, consecutive-chunking for MARK_ATTENDANCE, exponential backoff (cap 30s), max 5 retries → DLQ.
- **DLQ:** `DeadLetterQueue` — Hive-backed, 100-entry cap, 30-day prune, UI-warning on eviction.
- **Handlers:** 7 `SyncHandler` implementations (attendance, student, servant, team, results, pastoral, session).
- **Background:** Workmanager (15-min periodic, Android), lifecycle resume trigger.
- **DI:** 14 action → handler mappings in `injection.dart`.
- **Known issue:** `CLEAR_ATTENDANCE` handler loops back into repository enqueue (never reaches Firestore delete).

## Project Structure
```
lib/
├── core/       # DI, services (sync, DLQ, pruning), constants, models, theme, utils, widgets
├── features/   # admin, attendance, auth, devtools, results, servant, student, team
├── shared/     # shared widgets
└── l10n/       # localization
```

## Recent Milestones (2026)
| Date | Milestone |
|------|-----------|
| May | Offline-first sync & Clean Architecture migration |
| Jun | Project-state-audit gap analysis |
| Jun | Codebase-hardening (architectural & security audit remediation) |
| Jun | HivePruningService (30-day retention), DLQ + exponential backoff |
| Jul | Senior code review remediation (all critical/important issues) |
| Jul | WIP: SyncEngineStatus rename, error classifier, Firestore rules hardening |
