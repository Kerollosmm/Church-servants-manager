# Original User Request

## Initial Request — 2026-06-09T14:48:59+03:00

Refactor CSMS Firestore security rules, repository write patterns, and query structures to eliminate Spark-tier billing leaks, implement deterministic document IDs, and enforce a strict offline-first outbox architecture.

Working directory: c:\Users\KimoStore\church_managment_system

## Requirements

### R1. Remove Rules-based Cost Leaks in firestore.rules
Eliminate all `get()` and `exists()` checks from `firestore.rules`. User permissions, sectors, and teams must be checked against custom claims or local Hive boxes validated on login gating.

### R2. Refactor Write Patterns to Pure Outbox (Hive-first)
Ensure all repository mutation methods (create, update, delete) in `StudentDataRepository` and `AttendanceMarkRepository` use the pattern:
Write to Local Hive -> Attempt Firestore sync -> On catch/network failure, enqueue SyncEntry to user-scoped `sync_queue_{userId}` Hive box.

### R3. Deterministic Document IDs
Mutations must generate and use deterministic IDs (e.g. `studentId_sessionId` or hashed identity strings) on the client side to achieve LWW idempotency.

### R4. Query Optimization
Enforce query bounds and utilize explicit `Source.serverAndCache` get options for all single document reads.

## Acceptance Criteria

### Security Rules
- [ ] No `exists()` or `get()` calls exist inside `firestore.rules`.
- [ ] Rules-test suite passes successfully.

### Sync & Storage
- [ ] Direct online write bypasses are removed from repository logic.
- [ ] User queue boxes are fully isolated under `sync_queue_${userId}`.
- [ ] All tests in `test/core/services/sync_service_test.dart` pass.
