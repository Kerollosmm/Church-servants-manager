# Tasks: AI-Enhanced Offline-First Attendance System

**Feature:** AI-Enhanced Offline-First Attendance System
**Plan:** [plan.md](./plan.md)
**Spec:** [spec.md](./spec.md)
**Created:** 2026-04-22

---

## Phase 1: Setup
- [x] T001 Initialize feature directory and update `.specify/features/018-ai-attendance-system/research.md` with base findings
- [x] T002 Research AI prompt safety and quota management for Spark plan in `.specify/features/018-ai-attendance-system/research.md`

## Phase 2: Foundational Prerequisite
- [x] T003 [P] Add `attendanceSummary` and `aiRecommendations` fields to Student and Servant models in `lib/features/student/data/models/student_model.dart` and `lib/features/servant/data/models/servant_model.dart`
- [x] T004 [P] Update Firestore security rules for `aiRecommendations` visibility in `firestore.rules`
- [x] T005 Add Firestore collection name constants in `lib/core/constants/firestore_collections.dart` (created firestore_fields.dart)

## Phase 3: [US1] Servant Get Trend Insight
**Goal:** Servant receives natural language insights about group attendance patterns.
**Test Criteria:** Calling `getAttendanceInsight` with valid `groupId` returns a non-empty insight string based on aggregated data.

- [x] T006 [P] [US1] Implement `getAttendanceInsight` callable Cloud Function in `functions/src/admin.ts` (implemented in ai_logic.ts)
- [x] T007 [P] [US1] Define `IAttendanceInsightRepository` interface in `lib/features/attendance/domain/repos/i_attendance_insight_repository.dart`
- [x] T008 [US1] Implement `AttendanceInsightRepository` using Firebase Functions in `lib/features/attendance/data/repos/attendance_insight_repository.dart`
- [x] T009 [US1] Create `GetGroupInsightUseCase` in `lib/features/attendance/domain/use_cases/get_group_insight_use_case.dart`
- [x] T010 [US1] Create `AttendanceInsightCard` widget in `lib/features/attendance/presentation/widgets/attendance_insight_card.dart`

## Phase 4: [US2] Servant Smart Query (RE-OPENED: Missing full implementation)
**Goal:** Servant identifies specific student groups (e.g., "absent 3 weeks") via natural language chat.
**Test Criteria:** User query "absent for 3 weeks" returns a filtered list of matching students in the chat panel.

- [ ] T011 [US2] Implement `smartQuery` Cloud Function that translates text to Firestore queries in `functions/src/admin.ts` (currently stubbed)
- [x] T012 [US2] Create `SmartQueryChatPanel` widget and integrate into `lib/features/attendance/presentation/screens/attendance_home_screen.dart`
- [x] T013 [US2] Update `AttendanceBloc` in `lib/features/attendance/presentation/bloc/attendance_bloc.dart` to handle chat state

## Phase 5: [US3] Student Get Encouragement
**Goal:** Student sees motivational messages based on their personal attendance consistency.
**Test Criteria:** Student home screen displays a personalized message when `aiRecommendations.encouragement` is present in Firestore.

- [x] T014 [P] [US3] Implement `getStudentEncouragement` Cloud Function in `functions/src/student_ai.ts`
- [x] T015 [US3] Create `EncouragementHeader` widget in `lib/features/student/presentation/widgets/encouragement_header.dart`
- [x] T016 [US3] Integrate encouragement display in `lib/features/student/presentation/screens/student_home_screen.dart`

## Phase 6: [US4] Servant Suggested Actions
**Goal:** AI provides actionable next steps (e.g., "Call Student X") based on attendance risk.
**Test Criteria:** `AttendanceInsightCard` displays "Suggested Actions" section with clickable prompt buttons.

- [x] T017 [US4] Update `getAttendanceInsight` Cloud Function to return structured action objects in `functions/src/admin.ts` (implemented in ai_logic.ts)
- [x] T018 [US4] Implement suggested action action buttons in `lib/features/attendance/presentation/widgets/attendance_insight_card.dart`

## Phase 7: Backend Automation (RE-OPENED: Missing tests)
- [x] T019 [US1, US3] Implement `onSessionClosed` Firestore trigger to update `attendanceSummary` in `functions/src/triggers/update_aggregates.ts`

## Phase 8: Polish & Safety
- [x] T020 [P] Implement offline fallback UI logic (hide/disable AI prompts) in all AI-related widgets using `ConnectivityBloc` (implemented AIOfflineGate)
- [ ] T021 Run full integration test suite against Firebase Emulator to verify end-to-end AI flows

## Phase 9: [REMEDIATION] Mandatory Trigger Tests (P07)
- [ ] T022 [US1, US3] Implement unit tests for `onSessionClosed` using `firebase-functions-test` in `functions/test/triggers/update_aggregates.test.ts`
- [ ] T023 Verify `FieldValue.increment` behavior and aggregate consistency across Student/Class documents

---

## Implementation Strategy
- **MVP First:** Focus on US1 (Trend Insights) and US3 (Student Encouragement) as they deliver the most value with minimal UI complexity.
- **Incremental Delivery:** Deploy Firestore rules and aggregate triggers before surfacing UI widgets to ensure data is ready.
- **Parallel Opportunities:** T003, T004, T006, T007, T014, and T020 can be executed simultaneously across different agents.

## Dependencies
- US1 depends on Phase 2 (Foundational).
- US2 depends on US1.
- US4 depends on US1.
- Phase 7 (Backend Automation) is required for accurate data in all User Stories.
- Phase 9 (Remediation) is required for production readiness of Phase 7.
