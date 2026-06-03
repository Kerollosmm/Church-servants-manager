# CSMS Architecture

**Codename:** CSMS
**Status:** Active, Refactored Auth & Offline Logic

## Core Architecture
- **Clean Architecture:** Separated into `data`, `domain`, and `presentation` layers.
- **Identity vs Profile:** Firebase handles Auth (Identity), Firestore handles metadata (Profile).
- **RBAC:** Firestore-First RBAC. Rules perform direct lookups against the `servants` collection. (Custom claims were deprecated due to Spark Plan constraints).
- **Spark Plan Constraints:** No Cloud Functions. All logic is client-side. Strict optimization of Firestore reads/writes.
- **Offline-First:** Hive local storage cache. All repositories use `_cachedGet` to attempt `Source.cache` before `Source.server`.

## Authentication System
- **Provider:** `FirebaseIdentityProvider`.
- **Repository:** `FirebaseAuthRepository` (fetches user using `Source.serverAndCache`, caches in `AuthUserLocalStore`).
- **Security:** `AuthFreshnessPolicy` (15-min write window).
- **UI States:** `AuthAuthenticated`, `AuthDegraded` (read-only/offline), `AuthArchived`.
- **Gating:** `AdminGate` ensures administrative access with session freshness.

## Implementation Details
- Firestore `servants` collection authoritative for: `role`, `isArchived`, `assignedTeamIds`.
- Offline support: `_cachedGet` ensures UI functions smoothly offline.
- Quota optimization: Queries are paginated `.limit(30)`, debounced, and batch writes are idempotent using deterministic document IDs (e.g. `studentId_sessionId`).