# PR #57 Fixes Implementation Plan (Updated)

This plan addresses all issues identified across both review passes of PR #57.

## Phase 1: Security Hardening (High Priority)

### 1. `firestore.rules` - Privileged Field Injection & Invitation logic
- **Issue:** `Users` create rule allows injection of `role`, `assignedTeamIds`, `isArchived`.
- **Fix:** Add `request.resource.data.keys().hasOnly(['uid', 'email', 'name', 'role', 'phone', 'avatarUrl', 'createdAt', 'updatedAt'])` and validate `role` matches invitation or is 'student'.
- **Issue:** Invitation claiming transition should be one-way and checked.
- **Fix:** Require `resource.data.status == 'pending' && request.resource.data.status == 'claimed' && request.resource.data.claimedByUid == request.auth.uid`.

### 2. `student_profile_cubit.dart` - Profile Ownership Check
- **Issue:** `setupProfile` allows creating any student profile.
- **Fix:** Add guard: `actor.role == UserRole.student && newStudent.uid == actor.uid`.

### 3. `tools/set_custom_claims.js` - Full Claim Sync
- **Issue:** Only syncs `role`, preserving stale team assignments or archived status.
- **Fix:** Read full user doc from Firestore and set `role`, `assignedTeamIds`, and `isArchived` in claims.

### 4. `can_mutate_student_usecase.dart` - Explicit Allowlist
- **Issue:** (Done in pass 1, but will verify) Switched from blacklist to allowlist.

## Phase 2: Data Integrity & Robustness

### 5. `attendance_repository.dart` - Idempotent closeSession
- **Issue:** Fallback path for large groups risks partial closure if retried.
- **Fix:** Use a transaction for the final batch (session close + group aggregate) to verify `isClosed == false` before writing, ensuring idempotency.

### 6. `student_model.dart` - Strict Integer Parsing
- **Issue:** `readInt` truncates decimals (e.g., 11.9 -> 11).
- **Fix:** Change logic to only accept numbers where `val % 1 == 0`.

### 7. `firebase_auth_repository.dart` - Error Mapping
- **Issue:** `refreshCurrentAppUser` lacks `AuthErrorMapper` usage.
- **Fix:** Wrap in try-catch and map exceptions to domain failures.

### 8. `student_query_service.dart` - Data Truncation
- **Issue:** (Done in pass 1) Removed hardcoded .limit(100).

## Phase 3: UI/UX & Architecture

### 9. `team_dropdown.dart` - Sentinel Leakage
- **Issue:** Callers see `allTeamsSentinel` instead of `null`.
- **Fix:** In `onChanged`, if value is sentinel, pass `null` to the callback.

### 10. `student_data_bloc.dart` - State Preservation
- **Issue:** Previous student list lost during reload.
- **Fix:** Copy current `students` list into the `StudentDataLoading` state.

### 11. `lib/core/di/injection.dart` - Graceful AI Fallback
- **Issue:** Throws error if `GEMINI_API_KEY` is missing.
- **Fix:** Register `NoOpStudentAIService` (needs creation) if key is empty.

## Phase 4: Documentation (Done Last)

### 12. `documentation/architecture.md` - Hive vs Firestore Reality
- **Issue:** Docs claim Hive-first, but implementation is Firestore-cache-first.
- **Fix:** Update docs to reflect reality: Cloud Firestore with Local Persistence as the primary mechanism, Hive reserved for future complex sync needs.

### 13. `.specify/features/018-ai-attendance-system/tasks.md` - Outdated Completion Status
- **Issue:** Tasks claim Cloud Function files exist (they were deleted).
- **Fix:** Update task descriptions to reflect client-side implementation and uncheck/re-check correctly.
