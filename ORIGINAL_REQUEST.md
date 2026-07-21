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

## Follow-up — 2026-07-16T12:54:57Z

The goal is to conduct a detailed, comprehensive code review of the entire `lib/features/` and `lib/core/` codebase of the ChurchServers Management System (CSMS), evaluating it against CSMS architectural rules, offline-first constraints, role-based access, clean code principles, and Firestore cost expectations. The analysis must also verify whether the app compiles and tests pass, and output the report to `review/code_review_report.md`.

Working directory: c:\Users\KimoStore\church_managment_system
Integrity mode: development

## Requirements

### R1. Analyze Entire Core and Feature Codebase
Review all files under `lib/core/` and `lib/features/` against CSMS guidelines (offline-first Hive SSOT, Firestore Spark plan limits, BLoC pattern, dependency injection, and clean code rules).

### R2. Verify App Execution and Tests
Run `flutter analyze` and `flutter test` on the codebase to ensure it compiles without warnings/errors and passes all tests.

### R3. Optimize for Token Usage (Caveman Mode)
The team and all subagents must operate under high-intensity caveman mode to reduce token usage and compress outputs.

### R4. Save Structured Code Review Report
Output the final, detailed report to `review/code_review_report.md`. The report must integrate the CSMS Reviewer, CSMS Code Reviewer checklist, clean code analysis, and test run results.

## Acceptance Criteria

### Execution & Quality Verification
- [ ] Code compiles without static analysis errors (`flutter analyze` passes).
- [ ] All unit and widget tests pass successfully (`flutter test` passes).

### Output Formatting and Content
- [ ] A review report markdown file is saved to `review/code_review_report.md`.
- [ ] The report includes:
  - **Review Summary**: Overall quality, health, and release readiness.
  - **What Was Done Well**: Architecture and coding wins.
  - **Critical Issues**: High-severity issues that must be fixed before release.
  - **Important Issues**: Medium-severity issues.
  - **Suggestions**: Low-severity recommendations.
  - **Offline and Sync Check**: Pass/Fail for local-write-first, duplicate protection, syncStatus, retry, and conflict handling.
  - **Security Check**: Pass/Fail for RBAC, student isolation, rules dependency, and client-side check avoidance.
  - **Firestore Cost Check**: Read/Write/Listener efficiency (Good/Warning/Bad) and batch opportunities.
  - **Testing Gaps**: Missing unit, widget, or integration tests.
  - **Clean Code Review**: Adherence to DRY, SOLID, KISS, and YAGNI.
  - **Merge Decision**: Approved / Approved with fixes / Needs changes / Blocked.

