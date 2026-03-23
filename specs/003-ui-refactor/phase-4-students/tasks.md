# Phase 4 Tasks — Student Feature Screens

## Prerequisites
- [x] Phase 1 complete — atoms/molecules/organisms available
- [x] Phase 2 complete
- [x] Phase 3 complete

---

## Task 4.0 — Exploration
- [ ] Read `student_home_screen.dart` → understand current BLoC and data model usage
- [ ] Read `student_profile_screen.dart`, `student_edit_screen.dart`, `student_detail_screen.dart`
- [ ] Read `lib/features/student/presentation/bloc/` for existing states
- [ ] Read `lib/features/student/presentation/widgets/` to inventory reusable widgets

---

## Task 4.1 — Refactor Student List Screen
**File:** `lib/features/student/presentation/screens/student_home_screen.dart`

- [ ] Wrap root with `Directionality(textDirection: TextDirection.rtl)`
- [ ] Replace scaffold with `AppScreenShell`
- [ ] Replace any existing AppBar with `AppHeader(title: 'الطلاب')`
- [ ] Extract `_StudentSearchBar extends StatelessWidget`:
  - [ ] Uses `AppSearchBar`
  - [ ] Dispatches search/filter event to existing BLoC
- [ ] Extract `_AddStudentButton extends StatelessWidget`:
  - [ ] `AppPrimaryButton(label: 'إضافة طالب')` — full width, navigates to add screen
- [ ] Extract `_StudentList extends StatelessWidget`:
  - [ ] `ListView.builder` with `AppPersonListTile`
  - [ ] `RefreshIndicator` wrapping list
  - [ ] Each tile: `onTap` → navigate to profile screen
  - [ ] When list empty: `AppEmptyState`
  - [ ] Profile avatar: `AppAvatar` with initials if no photo URL
  - [ ] Trailing: `AppBadge` with attendance % color-coded
- [ ] Verify: no `setState` or logic in `build()` — use BLoC listeners
- [ ] Verify: `const` wherever possible
- [ ] `flutter analyze` → 0 errors

## Task 4.2 — Refactor Student Profile Screen
**File:** `lib/features/student/presentation/screens/student_profile_screen.dart`

- [ ] Replace with `CustomScrollView` + `SliverToBoxAdapter` structure
- [ ] Extract `_ProfileHero(student) extends StatelessWidget`:
  - [ ] Stack: gradient background (primaryContainer → background) + centered `AppAvatar(radius: 48)`
  - [ ] Name in `titleLarge`, grade/group in `bodyMedium` below avatar
  - [ ] Height: ~200px
- [ ] Extract `_PersonalInfoCard(student) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'المعلومات الشخصية')`
  - [ ] Multiple `AppInfoRow` widgets: Birth date, Phone, Address, Group, Servant
- [ ] Extract `_AttendanceSummaryCard(student) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'الحضور')`
  - [ ] `AppStatCard` showing attendance % + ratio
  - [ ] `LinearProgressIndicator` (ochre color) showing visual %
- [ ] Extract `_RecentAttendanceCard(records) extends StatelessWidget`:
  - [ ] `AppSectionCard(headerTitle: 'آخر الجلسات')`
  - [ ] List of up to 5 `AppInfoRow` (date + `AppBadge` status)
- [ ] Extract `_ProfileActions extends StatelessWidget`:
  - [ ] `Row` with Edit button (outlined) and Delete button (destructive text)
  - [ ] Edit → navigate to student edit screen
  - [ ] Delete → show confirmation dialog then dispatch delete event
- [ ] `flutter analyze` → 0 errors

## Task 4.3 — Refactor Add/Edit Student Screen
**File:** `lib/features/student/presentation/screens/student_edit_screen.dart`

- [ ] Replace with `AppScreenShell`
- [ ] `AppHeader(title: isEditing ? 'تعديل طالب' : 'إضافة طالب')`
- [ ] Wrap body in `SingleChildScrollView` → `AppSectionCard`
- [ ] Avatar picker at top:
  - [ ] `GestureDetector` wrapping `AppAvatar(radius: 48)`
  - [ ] Bottom-right edit icon overlay using `Stack`
  - [ ] `onTap` → image picker (existing logic) or placeholder
- [ ] Form fields using `AppInputField`:
  - [ ] Name (required, min 2 chars)
  - [ ] Birth Date → `TextFormField` read-only + `showDatePicker()` on tap
  - [ ] Phone
  - [ ] Address
- [ ] Dropdowns using `DropdownButtonFormField` styled with `InputDecorationTheme`:
  - [ ] Grade
  - [ ] Group/Team
  - [ ] Assigned Servant
- [ ] `AppPrimaryButton(label: 'حفظ', isLoading: state.isSubmitting)` full width
- [ ] `AppTextButton(label: 'إلغاء')` → pop navigation
- [ ] On success state: auto-pop and show SnackBar
- [ ] `flutter analyze` → 0 errors

## Task 4.4 — Refactor Student Attendance History
**File:** `lib/features/student/presentation/screens/student_detail_screen.dart`
(confirm actual file during Task 4.0)

- [ ] `AppHeader(title: 'سجل الحضور', subtitle: studentName)`
- [ ] Summary card: `AppSectionCard` with total sessions / attended + %
- [ ] `ListView.builder` for attendance entries:
  - [ ] Each: `AppInfoRow(label: dateFormatted, value: sessionTitle)` + `AppBadge`
  - [ ] Badge: حاضر (green), غائب (red), معذور (orange)
- [ ] `AppEmptyState` when no records
- [ ] `flutter analyze` → 0 errors

## Task 4.5 — Update Existing Student Widgets
- [ ] Check `lib/features/student/presentation/widgets/` for any widgets to update
- [ ] Replace any hardcoded colors with `AppColors.*`
- [ ] Replace any inline padding with `AppSpacing.*`
- [ ] Replace helper `_buildXxx()` methods with private `StatelessWidget` classes

## Task 4.6 — Widget Tests
**Files:** `test/features/student/`

- [ ] `student_home_screen_test.dart`:
  - [ ] Renders student list when state has students
  - [ ] Shows empty state when list is empty
  - [ ] Search bar dispatches filter event
- [ ] `student_profile_screen_test.dart`:
  - [ ] All info rows render
  - [ ] Delete button shows confirmation dialog
- [ ] Run: `flutter test test/features/student/`

## Task 4.7 — Visual QA
- [ ] Run app: navigate to Student List → compare Stitch screenshot
  - ✅ AppPersonListTile with avatar, name, attendance badge
  - ✅ Search bar visible
  - ✅ RTL layout
- [ ] Navigate to Student Profile → compare Stitch screenshot
  - ✅ Gradient hero header
  - ✅ Info rows with dividers
  - ✅ Attendance progress bar (ochre)
- [ ] Open Add Student form → compare Stitch screenshot
  - ✅ Avatar picker circle at top
  - ✅ All form fields present

## Task 4.8 — Final Check
- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → all tests pass
