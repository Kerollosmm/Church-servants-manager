# 012 - UI Clean Refactor Plan

## Objective
Implement and refactor all app UI to match designs in `UI Screens/` using clean Flutter architecture, reusable components, and phase-based delivery.

## UI Source of Truth
- `UI Screens/splash_screen_restored`
- `UI Screens/login_screen_with_logo`
- `UI Screens/admin_dashboard_matched_header`
- `UI Screens/servant_dashboard_with_logo`
- `UI Screens/student_list`
- `UI Screens/student_profile_details`
- `UI Screens/add_edit_student`
- `UI Screens/attendance_history`
- `UI Screens/create_attendance_session`
- `UI Screens/attendance_taking`
- `UI Screens/student_attendance_history`
- `UI Screens/servant_list`
- `UI Screens/servant_profile_details`
- `UI Screens/add_edit_servant`

## Phase Folders
- `phase-1-foundation/`
- `phase-2-auth/`
- `phase-3-dashboards/`
- `phase-4-student/`
- `phase-5-attendance/`
- `phase-6-servant/`

Each phase contains:
- `plan.md`: architecture + UI decisions + file scope
- `tasks.md`: execution checklist

## Required Flutter Skills
- `flutter-architecture`: feature-first + clean layering
- `flutter-building-layouts`: responsive and overflow-safe layout
- `flutter-theming-apps`: shared theme tokens only
- `flutter-building-forms`: all input screens
- `flutter-managing-state`: Cubit/BLoC state isolation
- `flutter-improving-accessibility`: semantics + tap-target rules
- `flutter-testing-apps`: widget tests for each refactored screen

## Clean Code Rules
1. Keep feature-first structure (`features/*/presentation|domain|data`).
2. No inline color/spacing magic numbers in screens.
3. Prefer composition widgets over large `build()` methods.
4. Reuse core atoms/molecules/organisms before creating new widgets.
5. Keep business logic out of UI widgets.
6. Add/adjust widget tests after each phase.

## Completion Gate Per Phase
1. `flutter analyze` passes.
2. impacted widget tests pass.
3. visual match checked against `UI Screens/<screen>/screen.png`.
4. no overflow on small phone width.
