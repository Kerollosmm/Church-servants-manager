# Phase 5 Tasks — Servant & Attendance Feature Screens

## Prerequisites
- [x] Phase 1 complete — atoms/molecules/organisms available
- [x] Phase 2 complete
- [x] Phase 3 complete
- [x] Phase 4 complete

---

## Task 5.0 — Exploration
- [ ] Read `servant_list_screen.dart`, `servant_detail_screen.dart`, `add_edit_servant_screen.dart`
- [ ] Read `lib/features/servant/presentation/bloc/` for existing states
- [ ] Read `attendance_history_screen.dart`, `attendance_session_create_screen.dart`, `attendance_taking_screen.dart`, `student_attendance_screen.dart`
- [ ] Read `lib/features/attendance/presentation/bloc/` for existing states

---

## Flutter Skills to Follow (MANDATORY)

Before implementing each screen, read and apply the relevant skill from `.agent/skills/`:

| Skill | Apply When |
|---|---|
| `flutter-building-layouts` | Any layout changes — use constraint system, avoid overflow |
| `flutter-building-forms` | Add/Edit Servant form, Create Session form |
| `flutter-managing-state` | Attendance Taking toggle state, filter chips state |
| `flutter-animating-apps` | Attendance Taking status toggle animation, list transitions |
| `flutter-theming-apps` | All screens — ensure `ThemeData` + `OchreTheme` extension used |
| `flutter-testing-apps` | Writing widget tests for each screen (AAA pattern) |
| `flutter-improving-accessibility` | `Semantics` labels on toggle buttons, badges |

---

## Task 5.1 — Refactor Servant List Screen
**File:** `lib/features/servant/presentation/screens/servant_list_screen.dart`

> Follow `flutter-building-layouts` skill for layout constraints

- [ ] Wrap root with `Directionality(textDirection: TextDirection.rtl)`
- [ ] Replace scaffold with `AppScreenShell`
- [ ] Add `AppHeader(title: 'الخدام', subtitle: '${count} خادم')`
- [ ] Extract `_ServantSearchBar extends StatelessWidget` (uses `AppSearchBar`)
- [ ] Extract `_AddServantButton extends StatelessWidget` (`AppPrimaryButton` → navigate to add screen)
- [ ] Extract `_ServantList extends StatelessWidget`:
  - [ ] `ListView.builder` with `AppPersonListTile`
  - [ ] `RefreshIndicator` wrapping
  - [ ] Each tile: avatar, name, team, student count badge (`AppBadge`)
  - [ ] Tap → Servant Profile
  - [ ] Empty: `AppEmptyState(message: 'لا يوجد خدام مسجلون')`
- [ ] `const` constructors throughout
- [ ] `flutter analyze` → 0 errors

## Task 5.2 — Refactor Servant Profile Screen
**File:** `lib/features/servant/presentation/screens/servant_detail_screen.dart`

> Follow `flutter-building-layouts` skill for `CustomScrollView` structure

- [ ] Structure: `CustomScrollView` + `SliverToBoxAdapter` sections
- [ ] Extract `_ServantHero(servant) extends StatelessWidget`:
  - [ ] Gradient background top: `primaryContainer` → `background`
  - [ ] `AppAvatar(radius: 48)` centered
  - [ ] Name in `titleLarge`, role/title in `bodyMedium`
- [ ] Extract `_ServantInfoCard(servant) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'المعلومات')`
  - [ ] `AppInfoRow` for: Phone, Email, Join date, Team
- [ ] Extract `_ServantStudentsCard(students) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'طلابي')`
  - [ ] First 5 `AppPersonListTile` + "عرض الكل" `AppTextButton`
- [ ] Extract `_ServantSessionsCard(sessions) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'الجلسات الأخيرة')`
  - [ ] Last 3 sessions with date + group
- [ ] Extract `_ServantActions extends StatelessWidget`:
  - [ ] Edit + Delete buttons
- [ ] `flutter analyze` → 0 errors

## Task 5.3 — Refactor Add/Edit Servant Screen
**File:** `lib/features/servant/presentation/screens/add_edit_servant_screen.dart`

> Follow `flutter-building-forms` skill for form validation and field structure

- [ ] `AppScreenShell` wrapper
- [ ] `AppHeader(title: isEditing ? 'تعديل خادم' : 'إضافة خادم')`
- [ ] `SingleChildScrollView` → `AppSectionCard`
- [ ] Avatar picker: `Stack(children: [AppAvatar(radius: 48), _EditIconOverlay()])`
- [ ] Form with `GlobalKey<FormState>`, `AutovalidateMode.onUserInteraction`
- [ ] `AppInputField` for: Name (required), Phone, Email
- [ ] `DropdownButtonFormField` for: Role, Assigned Group
- [ ] `AppPrimaryButton(label: 'حفظ', isLoading: state.isSubmitting)` full width
- [ ] `AppTextButton(label: 'إلغاء')` → pop navigation
- [ ] On success → auto-pop + SnackBar confirmation
- [ ] `flutter analyze` → 0 errors

## Task 5.4 — Refactor Attendance History Screen
**File:** `lib/features/attendance/presentation/screens/attendance_history_screen.dart`

> Follow `flutter-building-layouts` skill for sticky filter row

- [ ] `AppScreenShell` + `AppHeader(title: 'سجل الحضور')`
- [ ] Extract `_FilterChipsRow extends StatelessWidget`:
  - [ ] `ChoiceChip` row: الكل / هذا الأسبوع / هذا الشهر
  - [ ] `selectedColor: AppColors.primary`, text white when selected
  - [ ] Dispatches filter event to existing BLoC
  - [ ] `SingleChildScrollView(scrollDirection: Axis.horizontal)` for overflowing chips
- [ ] Extract `_SessionList extends StatelessWidget`:
  - [ ] `ListView.builder` + `RefreshIndicator`
  - [ ] Each: `_SessionCard` → `AppSectionCard` compact showing date, name, counts
  - [ ] Tap → navigate to session detail or attendance taking review
  - [ ] Empty: `AppEmptyState(message: 'لا توجد جلسات مسجلة')`
- [ ] `flutter analyze` → 0 errors

## Task 5.5 — Refactor Create Attendance Session Screen
**File:** `lib/features/attendance/presentation/screens/attendance_session_create_screen.dart`

> Follow `flutter-building-forms` skill

- [ ] `AppScreenShell` + `AppHeader(title: 'جلسة جديدة')`
- [ ] `SingleChildScrollView` → `AppSectionCard`
- [ ] Form fields:
  - [ ] Session name: `AppInputField` (required)
  - [ ] Date: `AppInputField` read-only → `showDatePicker()` on tap (calendar icon)
  - [ ] Group: `DropdownButtonFormField`
  - [ ] Notes: `AppInputField(maxLines: 3)` optional
- [ ] `AppPrimaryButton(label: 'ابدأ الجلسة', isLoading: state.isCreating)`
- [ ] On success: navigate to `AttendanceTakingScreen` with session ID
- [ ] `flutter analyze` → 0 errors

## Task 5.6 — Refactor Attendance Taking Screen
**File:** `lib/features/attendance/presentation/screens/attendance_taking_screen.dart`

> Follow `flutter-managing-state` skill for local toggle state
> Follow `flutter-animating-apps` skill for status toggle animation

- [ ] `AppScreenShell` + `AppHeader(title: sessionTitle, subtitle: dateFormatted)`
- [ ] Extract `_AttendanceProgressBar(present, total) extends StatelessWidget`:
  - [ ] Row: "الحضور: x / y" label + `LinearProgressIndicator(color: AppColors.primary)`
  - [ ] Padding: `AppSpacing.spacingM`
- [ ] Extract `_StudentAttendanceList extends StatelessWidget`:
  - [ ] `ListView.builder` with `_AttendanceTile` — use `ListView.builder` not `Column` (performance)
  - [ ] Never use `shrinkWrap: true` here — this is the full-scroll body
- [ ] Extract `_AttendanceTile extends StatelessWidget`:
  - [ ] `AppPersonListTile` + trailing `_StatusToggle`
- [ ] Extract `_StatusToggle extends StatefulWidget`:
  - [ ] Local `ValueNotifier<AttendanceStatus>` (present / absent / excused)
  - [ ] `AnimatedSwitcher` with 200ms fade for icon transitions
  - [ ] Icons: check_circle / cancel / remove_circle_outline
  - [ ] Colors: green / red / orange
  - [ ] `Semantics(label: 'حالة الحضور', value: status.label)` for accessibility
  - [ ] On change → dispatch BLoC event
- [ ] `AppPrimaryButton(label: 'حفظ الجلسة')` inside `BottomAppBar` or `Padding` at bottom:
  - [ ] `SafeArea` wrapper
  - [ ] Shows count summary: "تم تسجيل x من y طالب"
- [ ] `flutter analyze` → 0 errors

## Task 5.7 — Refactor Student Attendance History Screen
**File:** `lib/features/attendance/presentation/screens/student_attendance_screen.dart`

- [ ] `AppHeader(title: 'سجل الحضور', subtitle: studentName)`
- [ ] Summary `AppSectionCard`: total / attended / % + `LinearProgressIndicator`
- [ ] `ListView.builder` of records:
  - [ ] Each: `AppInfoRow` (date label + session name) + trailing `AppBadge`
  - [ ] Badge colors: حاضر (green), غائب (red), معذور (orange)
- [ ] Empty: `AppEmptyState(message: 'لا توجد سجلات حضور')`
- [ ] `flutter analyze` → 0 errors

## Task 5.8 — Update Existing Servant/Attendance Widgets
- [ ] Check `lib/features/servant/presentation/widgets/` for widgets to update
- [ ] Check `lib/features/attendance/presentation/widgets/` for widgets to update
- [ ] Replace hardcoded colors → `AppColors.*`
- [ ] Replace hardcoded padding → `AppSpacing.*`
- [ ] Replace helper methods → private `StatelessWidget` classes

## Task 5.9 — Accessibility Audit
> Follow `flutter-improving-accessibility` skill

- [ ] All interactive toggle buttons have `Semantics(label: ..., value: ...)`
- [ ] `AppBadge` has `Semantics(label: statusDescription)`
- [ ] All buttons have minimum 48×48 touch target
- [ ] Color contrast ratio ≥ 4.5:1 for all text on backgrounds

## Task 5.10 — Widget Tests
> Follow `flutter-testing-apps` skill (AAA pattern)

**Files:** `test/features/servant/`, `test/features/attendance/`

- [ ] `servant_list_screen_test.dart`:
  - [ ] Renders `AppPersonListTile` per servant
  - [ ] Empty state when no servants
- [ ] `attendance_taking_screen_test.dart`:
  - [ ] `_StatusToggle` cycles through 3 states on tap
  - [ ] Save button shows correct count summary
  - [ ] `AnimatedSwitcher` renders correct icon per status
- [ ] `attendance_session_create_screen_test.dart`:
  - [ ] Form validates required fields
  - [ ] Button shows loading when BLoC is creating
- [ ] Run: `flutter test test/features/servant/ test/features/attendance/`

## Task 5.11 — Visual QA
- [ ] Servant List: compare to Stitch screenshot
- [ ] Servant Profile: compare to Stitch screenshot
- [ ] Add Servant: compare to Stitch screenshot
- [ ] Attendance History: compare to Stitch screenshot
- [ ] Create Session: compare to Stitch screenshot
- [ ] Attendance Taking: test cycling through all 3 status states, verify animated icon change
- [ ] Student Attendance History: verify AppBadge colors

## Task 5.12 — Full Project Final Check
- [ ] `flutter analyze` → 0 issues across all files
- [ ] `dart run build_runner build --delete-conflicting-outputs` (if using `freezed`/`json_serializable`)
- [ ] `flutter test` → ALL tests pass (including phases 1-4)
- [ ] `flutter build apk --debug` → builds successfully
- [ ] Manual E2E walkthrough: Login → Dashboard → Students → Attendance session → Take attendance → Save
