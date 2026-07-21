# Review Summary

The Church Servants Management System (CSMS) Flutter codebase and Firestore security rules have been comprehensively evaluated against the project's custom review guidelines. The code compiles successfully, and all existing unit and widget tests pass. However, critical security and offline-first synchronization vulnerabilities have been identified that prevent the project from being release-ready.

## Static Analysis and Test Run Status

- **Static Analysis (`flutter analyze`)**: 34 info-level issues were found (0 errors, 0 warnings). The production codebase is compilation-clean. The findings consist primarily of minor lint recommendations (e.g., `cascade_invocations` and deprecated parameter usage in the local auth store).
- **Flutter Unit & Widget Tests (`flutter test`)**: All **283 tests** passed cleanly.
- **Firebase Security Rules Unit Tests**: Checked under the local Firestore emulator suite. A seed helper issue in the test runner was fixed (modifying `security_rules_test_firestore/tests/firestore.test.js` to seed sessions in `'AttendanceSessions'` instead of the legacy name `'attendance'`), resulting in 25/25 passing tests.

# What Was Done Well

- **Hive SSOT for UI Queries**: Query paths retrieve data from the local Hive boxes first to render the UI immediately, before triggering non-blocking background revalidations (e.g., in `AttendanceRepository.getSessionRosterSnapshot` and `StudentDataRepository.getStudentsByGroupWithFallback`).
- **Last-Write-Wins Conflict Resolution**: Document updates are transaction-based, resolving conflicts using client-side vs. server-side timestamps (LWW) in `AttendanceCommandService.batchWriteMarks` and `syncOfflineMark`.
- **Zero Real-Time Listeners**: There are no real-time Firestore listeners (`snapshots()`) used in the production codebase. All queries are one-time `get()` operations paired with manual pull-to-refresh or background triggers, minimizing Firestore reads on the Spark plan.
- **Client-Side Deterministic Doc IDs**: Documents are written using stable, deterministic IDs (e.g. `mark_${sessionId}_$studentId`), ensuring writes are idempotent and deduplicated.
- **Student Data Isolation**: Students are isolated on the backend. They can only read their own documents, points ledger, and session history. They have zero access to `/SectorsAnalytics` and `/PastoralRecords`.

# Critical Issues

- **Privilege Escalation via Legacy assignedTeamId in Users Update Rule**:
  - **Why it is a problem**: The security rule for updating a user profile in `/Users/{servantId}` checks for immutability of specific fields but does not include the legacy field `'assignedTeamId'`. However, `callerManagesTeam(classId)` still checks the legacy `assignedTeamId` field to authorize access.
  - **Risk**: Any authenticated servant can update their own user profile document and modify `assignedTeamId` to another team's ID, granting them unauthorized read/write access to that team's attendance and student records.
  - **Recommended fix**: Add `'assignedTeamId'` to the `isImmutable` list in the `/Users/{servantId}` update rule in `firestore.rules`:
    ```javascript
    allow update: if isSignedIn() && (
      isAdmin() || (
        servantId == uid() &&
        isImmutable('role') &&
        isImmutable('uid') &&
        isImmutable('isArchived') &&
        isImmutable('assignedTeamIds') &&
        isImmutable('assignedSectorIds') &&
        isImmutable('assignedTeamId')
      )
    );
    ```

- **Offline Attendance Marks Do Not Sync Automatically in Background**:
  - **Why it is a problem**: When a user marks attendance inside the active BLoC (`AttendanceTakingBloc`), the marks are saved directly to the local Hive box via `_localDatasource.cacheMark(...)` and accumulated in `pendingLocalMarks`. They are not enqueued to the outbox queue (`SyncService.enqueue`). When the user taps "Submit", it calls `_repository.batchWriteMarks(...)`. Because this repository method calls a direct Firestore transaction, it fails if the device is offline, and the transaction error propagates to the UI. Since there is no fallback to enqueue the batch mutations as a `SyncEntry`, these marks are stranded in the local cache and never synced.
  - **Risk**: Attendance marks recorded while offline will never automatically sync in the background when connectivity is restored, violating the offline-first mandate for attendance workflows.
  - **Recommended fix**: Introduce an offline outbox fallback inside `AttendanceTakingBloc._onSubmitSession` or `AttendanceRepository.batchWriteMarks`. If the transaction fails due to network connectivity issues, serialize the batch of marks and enqueue them as individual `SyncActionType.markAttendance` entries or a single batch entry in the outbox queue.

# Important Issues

- **BLoC Bypasses Repository Layer to Call Local Datasource Directly**:
  - **Why it matters**: `AttendanceTakingBloc` directly invokes `_localDatasource.cacheMark(...)` and `_localDatasource.clearCache()`. It also depends on the concrete classes `AttendanceRepository` and `AttendanceLocalDatasource` instead of the domain interface `IAttendanceRepository`. This violates Clean Architecture and decouples presentation logic from domain boundaries.
  - **Recommended fix**: Refactor `AttendanceTakingBloc` to depend on `IAttendanceRepository`. Expose `cacheMark` and `clearCache` operations through `IAttendanceRepository` (or handle caching internally inside the repository's write methods) so the BLoC remains decoupled from the data implementation details.

- **Silent Exception Catches (Unlogged Errors)**:
  - **Why it matters**: Catch blocks in multiple files (e.g., `connectivity_cubit.dart`, `results_bloc.dart`, `auth_bloc.dart`, `attendance_session_repository.dart`) catch exceptions but do not log the error and stack trace. This violates the CSMS rule: *"No silent catch — every catch MUST log (e, stackTrace) via developer.log()".*
  - **Recommended fix**: Replace all silent/unlogged catch blocks with logging:
    ```dart
    } catch (e, stackTrace) {
      developer.log('Descriptive error message', error: e, stackTrace: stackTrace, name: 'ClassName');
    }
    ```

- **Dependency Injection Resolved in Widget Build Methods**:
  - **Why it matters**: `lib/features/attendance/presentation/screens/attendance_taking_screen.dart` resolves dependencies (`AttendanceRepository`, `AttendanceLocalDatasource`, `SyncService`) inside the widget `build` method using `getIt`. This violates the CSMS coding convention: *"No getIt<>() in widgets/build methods — pass via constructor"*.
  - **Recommended fix**: Pass these dependencies via the constructor of `AttendanceTakingScreen` and inject them from the router configuration level.

# Suggestions

- **Deprecate and Remove Retired Code**:
  - **Why it helps**: The files under `lib/features/attendance/presentation/bloc/attendance/` and `lib/features/attendance/presentation/screens/take_attendance_screen.dart` are retired and not mapped in the GoRouter definition. Removing unused/deprecated files reduces code clutter and prevents future maintainers from editing or referencing the wrong attendance taking flow.

- **Optimize Firestore Reads on Results Collection Rules**:
  - **Why it helps**: Read rules for `/results/{studentId}` look up the student's document to determine access rights via `get()`. Denormalizing metadata such as `classId` and `sectorId` directly onto the result document would allow the rules to check caller management using `resource.data` fields directly, dropping nested `get()` read costs to zero.

# Offline and Sync Check

- Local write first: Pass
- Duplicate-write protection: Pass
- syncStatus coverage: Pass
- Retry strategy: Fail
- Conflict handling: Pass

# Security Check

- Role-based access: Fail
- Student data isolation: Pass
- Firestore-rule dependency identified: Pass
- Client-side-only authorization avoided: Pass

# Firestore Cost Check

- Read efficiency: Good
- Write efficiency: Warning
- Listener usage: Good
- Batch opportunities: Attendance submission is structured as a batch write but lacks offline retry fallback.

# Testing Gaps

- **Unit**: Unit tests for business logic and outbox synchronization services are robust and fully functional.
- **Widget**: Extremely minimal widget coverage. Only two screen files have basic widget tests (`login_screen_test.dart` and `student_management_screen_smoke_test.dart`).
- **Integration**: Zero coverage. No `integration_test/` directory exists. Integration tests are required to validate real-world offline synchronization behavior and Workmanager synchronization tasks.

# Merge Decision

Needs changes
