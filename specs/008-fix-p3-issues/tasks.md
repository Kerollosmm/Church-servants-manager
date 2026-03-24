# Tasks: Fix P3 Backlog Issues

**Feature Branch**: `008-fix-p3-issues`
**Implementation Plan**: [plan.md](plan.md)

## Implementation Strategy

We will implement the P3 fixes in priority order, starting with the most impactful stability improvement (pagination) followed by UX enhancements (connectivity, session timer) and finally code quality (theme deprecation). Each phase is independently testable.

## Phase 1: Setup

- [ ] T001 Add `connectivity_plus: ^6.1.0` to `pubspec.yaml` using the pub tool
- [ ] T002 [P] Create `lib/core/services/connectivity_service.dart` interface and implementation
- [ ] T003 Register `ConnectivityService` as a lazy singleton in `lib/injection.dart`

## Phase 2: Foundational

- [ ] T004 [P] Create `ConnectivityState` using `freezed` in `lib/core/presentation/bloc/connectivity/connectivity_state.dart`
- [ ] T005 [P] Implement `ConnectivityCubit` in `lib/core/presentation/bloc/connectivity/connectivity_cubit.dart` to bridge the service and UI
- [ ] T006 Register `ConnectivityCubit` in `lib/injection.dart`

## Phase 3: [US1] Optimized List Loading (Priority: P1)

**Goal**: Implement Firestore pagination for student and servant lists.
**Test Criteria**: Scroll through 50+ items and verify batch loading with stable memory.

- [ ] T007 [P] [US1] Update `StudentDataState` to include pagination fields (lastDocument, isLoadingMore, hasReachedMax) in `lib/features/student/presentation/bloc/student_data/student_data_state.dart`
- [ ] T008 [US1] Update `StudentDataBloc` to handle pagination logic and cursor management in `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`
- [ ] T009 [P] [US1] Update `ServantDataState` to include pagination fields in `lib/features/servant/presentation/bloc/servant_data/servant_data_state.dart`
- [ ] T010 [US1] Update `ServantDataCubit` to handle pagination logic in `lib/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart`
- [ ] T011 [US1] Implement `PaginatedListView` pattern in `lib/features/student/presentation/screens/student_list_screen.dart` using a `ScrollController`
- [ ] T012 [US1] Implement `PaginatedListView` pattern in `lib/features/servant/presentation/screens/servant_list_screen.dart`

## Phase 4: [US2] Network Connectivity Awareness (Priority: P2)

**Goal**: Show a persistent offline indicator when disconnected.
**Test Criteria**: Toggle airplane mode and verify indicator appears/disappears within 2s.

- [ ] T013 [P] [US2] Create `OfflineIndicator` widget in `lib/core/widgets/offline_indicator.dart` following the UI contract
- [ ] T014 [US2] Wrap the main application content with `OfflineIndicator` in `lib/church_app.dart` or via a global `builder`

## Phase 5: [US3] Attendance Session Expiry Warning (Priority: P2)

**Goal**: Show countdown banner when < 10 mins remain.
**Test Criteria**: Verify banner appears at 10:00 remaining and updates every second.

- [ ] T015 [P] [US3] Create `AttendanceSessionTimerState` in `lib/features/attendance/presentation/bloc/timer/attendance_session_timer_state.dart`
- [ ] T016 [US3] Implement `AttendanceSessionTimerCubit` with `Timer.periodic` logic in `lib/features/attendance/presentation/bloc/timer/attendance_session_timer_cubit.dart`
- [ ] T017 [P] [US3] Create `SessionExpiryBanner` widget in `lib/features/attendance/presentation/widgets/session_expiry_banner.dart`
- [ ] T018 [US3] Integrate `SessionExpiryBanner` into `lib/features/attendance/presentation/screens/attendance_taking_screen.dart`

## Phase 6: [US4] Theme Token Cleanup (Priority: P3)

**Goal**: Deprecate legacy color aliases.
**Test Criteria**: IDE shows warnings for legacy aliases.

- [ ] T019 [P] [US4] Add `@Deprecated` annotations to legacy aliases in `lib/core/theme/app_colors.dart`

## Phase 7: Polish & Final Validation

- [ ] T020 Run `dart run build_runner build --delete-conflicting-outputs` to update all generated files
- [ ] T021 [P] Run all unit and widget tests: `flutter test`
- [ ] T022 Perform manual validation of all 4 user stories per `quickstart.md`

## Dependencies

1. Phase 1 & 2 must complete before Phase 4.
2. US1, US2, US3, and US4 are largely independent and can be implemented in any order once foundational tasks are done.

## Parallel Execution Opportunities

- **Setup (T001-T003)**: Can be done while someone else works on **Theme Cleanup (T019)**.
- **Pagination States (T007, T009)**: Can be done in parallel.
- **Timer & Offline Indicator UI (T013, T017)**: Can be developed in parallel as they use different Bloc/Cubit sets.
