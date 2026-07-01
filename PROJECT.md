# Project: CSMS Security Rules and Offline-First Sync Refactoring

## Architecture
- Client: Flutter (Mobile & Web) using Clean Architecture and BLoC/Cubit pattern.
- Backend: Firebase (Firestore, Authentication, Security Rules).
- Synchronization: Offline Sync Engine matching specifications.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | System Investigation | Locate and analyze security rules test suite, repository write patterns, document ID creation, and query structures | none | IN_PROGRESS |
| 2 | Pure Outbox & IDs Refactor | Refactor StudentDataRepository and AttendanceMarkRepository, introduce deterministic IDs, apply query options | M1 | PLANNED |
| 3 | Security Rules Cleanup | Eliminate get() and exists() from firestore.rules, ensure custom claims validation | M1 | PLANNED |
| 4 | Verification & Hardening | Run rules-test suite and sync_service_test.dart, run Challenger/Auditor to verify | M2, M3 | PLANNED |

## Interface Contracts
- Code layout compliance and rules/sync test verification.
