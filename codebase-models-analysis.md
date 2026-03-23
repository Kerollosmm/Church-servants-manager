# Codebase Models Analysis and Implementation Plan

## Overview
This document serves as our strategic plan for the next steps in developing and fixing the Church Management System. Based on the analysis of the feature models (`StudentModel`, `ServantModel`, `TeamModel`, `AttendanceSession`, and `AttendanceMark`) and the existing repository structure, the codebase follows a clean, feature-sliced architecture. The next phase of development focuses on addressing the critical and high-priority issues identified in the `REVIEW_REPORT.md`.

## Project Type
**MOBILE** (Flutter & Firebase)

## Success Criteria
- [ ] Complete understanding of the domain models and their relationships.
- [ ] Clear grouping of tasks to address P0, P1, P2, and P3 issues from the review report.
- [ ] Execution plan that safely refactors the database interactions (specifically fixing N+1 queries) without data loss.

## Tech Stack
- **UI Framework:** Flutter (Material 3)
- **Backend:** Firebase (Firestore, Auth)
- **Data Modeling:** Freezed + JSON Serializable
- **State Management / DI:** BLoC / get_it

## File Structure Analysis
The `lib/features/` directory contains the core vertical slices:
- `admin` - Admin UI and specific dashboards
- `attendance` - Contains `AttendanceSession`, `AttendanceMark`, `AttendanceStats` models and repositories
- `auth` - User provisioning and authentication models/services
- `devtools` - Internal diagnostic tools
- `servant` - `ServantModel` defining the servant users
- `student` - `StudentModel` defining the students
- `team` - `TeamModel` bridging servants and students into groups/classes

## Domain Relationships
- **Teams** link **Servants** (via `assignedServantId`) and represent a group or class.
- **Students** belong to a group/team (via `teamName` and `classId`).
- **AttendanceSessions** are created for a specific `teamId` and snapshot the assigned students.
- **AttendanceMarks** are individual records pointing to a `studentId`.

## Task Breakdown

### Task 1: Resolve P0 & P1 Critical / Security Risks
- **Agent:** `backend-specialist` / `mobile-developer`
- **Skills:** `firebase-best-practices`, `clean-code`
- **Input:** `admin_auth_client.dart`, `auth_data_repository.dart`, `app_router.dart`
- **Output:** Handled Cloud Functions availability, cleared Firestore persistence on sign-out, guarded `devTools` route, and proper error handling replacing silent `catch (_)`.
- **Verify:** Manual sign-out test confirms local cache clears; release build verification confirms `devTools` is unreachable.

### Task 2: Fix P2 Scalability Issues (N+1 Queries)
- **Agent:** `database-architect` / `mobile-developer`
- **Skills:** `database-design`, `performance-profiling`
- **Input:** `attendance_repository.dart`, Firestore schema
- **Output:** Introduction of `attendanceSummary` document per student/team to aggregate session logs, eliminating N+1 listeners and reads. Removal of hardcoded limit of 200 in student query.
- **Verify:** Firestore query usage graphs during local testing confirm O(1) reads instead of O(N).

### Task 3: Refactor `AttendanceRepository` God Class
- **Agent:** `mobile-developer` / `clean-code-expert`
- **Skills:** `architecture`, `clean-code`
- **Input:** `AttendanceRepository` (1000+ lines)
- **Output:** Split into `AttendanceSessionStore`, `AttendanceMarkStore`, `AttendanceRosterService`, and `AttendanceStatsService`.
- **Verify:** Unit tests pass against the new segregated services.

### Task 4: Address P3 Technical Debt & Testing Gaps
- **Agent:** `mobile-developer` / `test-engineer`
- **Skills:** `testing-patterns`
- **Input:** Feature files matching CRLF warnings, `enums.dart` (dead code), UI strings.
- **Output:** Lint fixes, removed dead files/enums, standardized RTL properties, and basic security rules tests written for Firebase Emulators.
- **Verify:** `checklist.py` passes all checks; `flutter test` completes successfully.

## Phase X: Verification
- [ ] Run `python .agent/scripts/checklist.py .` to ensure linting and security rules are met.
- [ ] Run test suite: `flutter test`
- [ ] Build verification: `flutter build apk`
- [ ] Code review passes with no regressions.
