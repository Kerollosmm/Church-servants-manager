# Jules AI Test Implementation Prompt

## Context
You are working on the **Church Servants Management System (CSMS)**, a Flutter app using Clean Architecture with Firebase/Hive offline-first storage.

## Current Issue
The admin dashboard was showing a generic Arabic error message ("تعذر تحميل بيانات لوحة التحكم") because the `Future.wait` in `AdminDashboardBloc` bundled all Firestore calls together. When the `collectionGroup` aggregate query failed (likely due to Spark-tier security rules or missing fields), the entire dashboard crashed.

## Fix Applied
- Split `Future.wait` into individual futures with independent error handling
- Added `catchError` to the stats future with fallback to zeroed `GlobalDashboardStats`
- Dashboard now shows partial data (students/servants/teams) even if stats fail
- Real error is logged via `developer.log` for debugging

## Test Coverage Gap
Current test coverage for the admin feature is only ~6% (1 out of 17 source files). The following critical files need comprehensive tests:

### 1. AdminDashboardBloc (CRITICAL)
**File:** `lib/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart`

**Test Scenarios:**
1. **Initial State:** Verify state starts as `AdminDashboardInitial`
2. **Loading State:** On `LoadDashboardData`, verify `AdminDashboardLoading` is emitted
3. **Success Path:** Verify `AdminDashboardLoaded` is emitted with correct `DashboardKpiData`
4. **Attendance Rate Calculation:**
   - Test `totalRosterEntries > 0`: Verify rate calculation is correct
   - Test `totalRosterEntries == 0`: Verify rate is 0.0 (no division by zero)
   - Test rate > 100%: Verify clamping to 100.0
5. **Stats Fallback (Your Fix):**
   - Mock `AdminStatisticsService` to throw an exception
   - Verify the dashboard still loads with `totalSessions: 0`, `totalPresent: 0`
   - Verify `developer.log` is called
6. **Repository Failure:** If any repository fails, verify `AdminDashboardError` is emitted with the Arabic message
7. **Parallel Execution:** Verify all four futures run in parallel via `Future.wait`

### 2. AdminTeamService (CRITICAL)
**File:** `lib/features/admin/data/admin_team_service.dart`

**Test Scenarios:**
1. **Validation (`_validateServantForTeam`):**
   - Test archived team rejection
   - Test non-servant role rejection
   - Test archived servant rejection
   - Test group ID mismatch rejection
2. **Transaction `assignServantToTeam`:**
   - Happy path: New servant assigned, previous servant's list updated
   - Idempotency: Re-assigning same servant doesn't crash
   - Failure: Team or servant not found
3. **Transaction `unassignServantFromTeam`:**
   - Happy path: Clears servant fields, updates old servant's list
   - No-op: Unassigning when no previous servant exists
4. **Helper `_extractAssignedTeamIds`:** Handles non-String values, empty strings, duplicates

### 3. AdminPolicy (HIGH)
**File:** `lib/features/admin/domain/admin_policy.dart`

**Test Scenarios:**
1. **`isAdmin`:** True for admin, false for servant/student/viewer
2. **`canAccessAdminArea`:**
   - True only if `isAdmin` AND `isFreshSession`
   - False if admin but stale session
   - False if non-admin
3. **`canManageTeams`, `canManageServants`, `canManageStudents`:** All return true only for admin

### 4. AdminStatisticsService (HIGH)
**File:** `lib/features/admin/data/services/admin_statistics_service.dart`

**Test Scenarios:**
1. **Model Serialization:** `GlobalDashboardStats` and `WeeklyStats` `toMap`/`fromMap` round-trip
2. **Cache Logic (Hive):**
   - Cache hit (valid TTL): Returns cached data, no Firestore call
   - Cache expired: Triggers Firestore query
   - Corrupted cache: Falls back to Firestore
   - `forceRefresh=true`: Skips cache
3. **Firestore Queries:**
   - `getGlobalDashboardStats`: Verifies `collectionGroup` aggregate query logic
   - `getWeeklyAttendanceStats`: Verifies subcollection query with date filtering

### 5. AdminGate (HIGH)
**File:** `lib/features/admin/presentation/widget/admin_gate.dart`

**Test Scenarios:**
1. **`AuthInitial` / `AuthLoading`:** Shows `CircularProgressIndicator`
2. **`AuthAuthenticated` (Admin + Fresh):** Shows child widget
3. **`AuthAuthenticated` (Non-Admin):** Shows `_AdminAccessDeniedScreen`
4. **`AuthAuthenticated` (Admin + Stale):** Shows `_AdminAccessDeniedScreen`
5. **`AuthDegraded`:** Shows "requires fresh session" message
6. **Button Actions:** "Refresh Session" button dispatches `AuthEventRefreshUser`

## Test File Structure
Create these 4 new test files:
1. `test/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc_test.dart`
2. `test/features/admin/data/admin_team_service_test.dart`
3. `test/features/admin/domain/admin_policy_test.dart`
4. `test/features/admin/data/services/admin_statistics_service_test.dart`

Update existing file:
- `test/features/admin/data/admin_team_membership_service_test.dart`: Add tests for removal, reassignment, and chunking

## Implementation Order
1. `admin_dashboard_bloc_test.dart` (Fix verification + regression prevention)
2. `admin_policy_test.dart` (Fast, pure logic)
3. `admin_team_service_test.dart` (Complex transaction logic)
4. `admin_statistics_service_test.dart` (Cache/Firestore interaction)
5. Expand `admin_team_membership_service_test.dart` (Edge cases)

## Dependencies
- `flutter_test` for widget tests
- `mockito` or `mocktail` for mocking repositories
- `bloc_test` for BLoC testing
- `fake_cloud_firestore` or similar for Firestore mocking
- `hive` test utilities for cache testing

## Project Knowledge Base
The project uses a memory system to persist context across conversations. The memory folder is located at:
`C:\Users\KimoStore\.openclaude\projects\C--Users-KimoStore-church-managment-system\memory\`

Key memory files to reference:
- `firebase_constraints.md`: Firebase Spark Plan constraints (no Cloud Functions, low requests)
- `user_kerollosmm.md`: User profile (Flutter/Firebase dev, prefers local branch reviews)
- `feedback_local_branch_review.md`: Adapt review process for git diff, not just PRs
- `reference_gemini_plans.md`: Architectural plans and task lists
- `reference_code_review_v1.md`: CSMS code review document with critical flaws
- `feedback_direct_execution.md`: User prefers immediate execution, no discussion needed
- `feedback_subagent_git_permissions.md`: Subagents cannot git commit; coordinator must commit manually
- `feedback_subagent_test_scope.md`: Instruct subagents to test full contract, not just new feature
- `feedback_backoff_test_delays.md`: Make backoff injectable to avoid slow tests
- `feedback_late_final_cascade_hazard.md`: late final + async init() causes race conditions
- `feedback_getit_circular_dependency.md`: Constructor injection causes stack overflow
- `project_custom_claims_doc_conflict.md`: CLAUDE.md says use Custom Claims but Spark plan can't
- `project_sprint1_foundation_hardening.md`: Sprint 1 completed 2026-05-17
- `feedback_assert_breaks_fallback.md`: Use debugPrint not assert(false) for warnings
- `reference_csms_architectural_mandates.md`: 6 official audit criteria
- `project_cms_audit_2026_05_17.md`: Audit results (82% score, 4 gaps remain)
- `project_audit_remediation_execution.md`: 9-task plan completed
- `feedback_prune_to_dlq_not_delete.md`: Old sync queue entries must move to DLQ
- `feedback_hive_box_open_guard.md`: Services must check isBoxOpen before calling Hive.box()
- `feedback_clean_architecture_interface_dependency.md`: Cubits must depend on domain interfaces
- `reference_firestore_collection_names.md`: Production uses PascalCase (Users, Classes, Students)
- `project_google_fonts_removed.md`: google_fonts removed, use bundled fonts only

## Success Criteria
- All test scenarios pass
- Code coverage for admin feature increases from 6% to >80%
- No regressions in existing functionality
- Tests follow Flutter testing best practices
