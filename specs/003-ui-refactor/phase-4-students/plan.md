# Phase 4 — Student Feature Screens

## Goal
Refactor all student-related screens to match Stitch designs using Phase 1 shared components.

---

## Stitch References
| Screen | Stitch ID | Screenshot |
|---|---|---|
| Student List | `2a49c37d0a754f7e9b30ebc79b5c2756` | [View](https://lh3.googleusercontent.com/aida/ADBb0ugAscKgR4dAl4EqV-Ab7YOV6GPE_AegzwlixZ6iAAd659-hqIb8ac6q5YNPTn4690gdwzF_INvfwGHXA7zeMrW84oT-jwfkfpOBZaivyzrZLo0EAkVXTQinX8HEHpL004hV3ogIbPF6bqSKV91Ahcg_VXrY7ZWTSNyTEEhgYTw6WFxKugC9TudAXdmPLsDRc3zRYNmIPlL0Cv9TxBpPkJgOUVWMe38ZvXuAa6FAazGUQVgTzgWfcsIP4V5C) |
| Student Profile Details | `e094de19e0b84e498bc20a6358e8c35e` | [View](https://lh3.googleusercontent.com/aida/ADBb0ujffU69Kz2IKevKww83PN1BpdfFQ1aOZwhAWs4HhqujQQgZroR_ic8b47LRKSFT43xFGSCm75GW4843CgndlraZyUS2E3Hf1Mu4bN1H1-XdgyS1Fm2KScLBjUcWyLL4V3AoN3w2XF5B_Nu1LMnn7MX3Iknowj9hnNod1F1tfgJ-7DbPkLoVcZM67g2Icr6vqa1dTLo7sbQqOKO1XYVyxoE4_DsWxIShDfo8qvARpS8Rjl9F79G1eTx0t5BF) |
| Add/Edit Student | `0fc429b6cf234945bb0670dc362752f8` | [View](https://lh3.googleusercontent.com/aida/ADBb0ugqQ2fCaex_8rfOFEXztSCkjVqohqY8S0oASPJVu2mUAszJ7A6Q4i_AhASo1hopuu0ybJfHJ1J1NiUiYG25_JKcVjkh-EQpNCQbY0LMTD_POOte-WlGS4bTG794Ee54eMYGU8Ck-VsjCt4KEEmJ0OOmWQrTib3-HIQXdHNNSNYC_-gFjotIEL9LvRUmsmkC3tsdMvLHK8h9IHtsr0R828lJEUuFQW1BGIBKVU5182V3CPC8AkSsnDtUOfi-) |
| Student Attendance History | `6101e677a7544d64baa5ea76c2b97bda` | [View](https://lh3.googleusercontent.com/aida/ADBb0uh1njOHeeZhL7lWbicqruonp4B-EXTyCKxSlKKI_LcbBRPoGbuv4d2MM61_9ktoUGFerhDzWgb3iMdR9TquUMh1jwYIZOpDFCQYKN-GwLlsfcmSHwWyCvI_ZQ8UtMdVWuqyv-cuYZxlCrZ75yjGUTLVAU3skKdXF8roRNPniy6Erar-Lq675r6Gj3NAv2g5fizy_ywa_LQqzq1EcuyaZUMSjcq0oxUBZ90HG279MYE9oe15PnLsewIpPpEt) |

---

## Screen Designs

### Student List
- `AppHeader` with "الطلاب" + student count badge
- `AppSearchBar` below header (filter by name)
- Floating `AppPrimaryButton` (FAB-style or inline) for "إضافة طالب"
- `ListView.builder` with `AppPersonListTile` for each student
  - Avatar (initials fallback), name, grade/group, attendance % badge
  - Tap → navigate to Student Profile
- `AppEmptyState` when list is empty
- Pull-to-refresh: `RefreshIndicator` wrapping list

### Student Profile Details
- **Hero header section** — large avatar (`AppAvatar`, radius 48), student name, grade
- Background: gradient from `primaryContainer` (top) to `background` (mid)
- Info section: `AppSectionCard` with multiple `AppInfoRow` widgets:
  - Birth date, Phone, Address, Team/Group, Servant
- Attendance summary: `AppSectionCard` — attendance % + visual bar
- Recent attendance history: `AppSectionCard` with last 5 sessions
- Action buttons row: Edit (outlined ochre) + Delete (red text button)

### Add/Edit Student
- `AppHeader` with "إضافة طالب" or "تعديل طالب"
- Single-scroll form in `AppSectionCard`:
  - Avatar picker circle at top (tap to upload image)
  - `AppInputField` for: Name, Birth Date (DatePicker), Phone, Address
  - Dropdown for: Grade, Group/Team, Assigned Servant
  - Save button: `AppPrimaryButton(label: 'حفظ')`
  - Cancel: `AppTextButton`

### Student Attendance History
- `AppHeader` with student name + "سجل الحضور"
- Summary card: Sessions attended / Total sessions + percentage
- `ListView.builder` of attendance entries:
  - Each entry: date + session name + `AppBadge` (حاضر/غائب/معذور)

---

## Implementation Plan

### 4.1 Student List
**File:** `lib/features/student/presentation/screens/student_home_screen.dart`

```dart
class StudentHomeScreen extends StatelessWidget {
  Widget build(context) => BlocBuilder<StudentBloc, StudentState>(
    builder: (context, state) => AppScreenShell(
      appBar: AppHeader(
        title: 'الطلاب',
        subtitle: '${state.students.length} طالب',
      ),
      body: Column(children: [
        const _StudentSearchBar(),
        const _AddStudentButton(),
        Expanded(child: _StudentList(students: state.filteredStudents)),
      ]),
    ),
  );
}

class _StudentSearchBar extends StatelessWidget {...}   // AppSearchBar
class _AddStudentButton extends StatelessWidget {...}   // AppPrimaryButton
class _StudentList extends StatelessWidget {            // ListView.builder + AppPersonListTile
  Widget build(context) => students.isEmpty
    ? AppEmptyState(message: 'لا يوجد طلاب مسجلون')
    : ListView.builder(itemBuilder: ..., itemCount: students.length);
}
```

### 4.2 Student Profile
**File:** `lib/features/student/presentation/screens/student_profile_screen.dart`

```dart
class StudentProfileScreen extends StatelessWidget {
  Widget build(context) => AppScreenShell(
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _ProfileHero(student: student)),
      SliverToBoxAdapter(child: _PersonalInfoCard(student: student)),
      SliverToBoxAdapter(child: _AttendanceSummaryCard(student: student)),
      SliverToBoxAdapter(child: _RecentAttendanceCard(records: records)),
      SliverToBoxAdapter(child: _ProfileActions()),
    ]),
  );
}
```

### 4.3 Add/Edit Student Form
**File:** `lib/features/student/presentation/screens/student_edit_screen.dart`

- `Form` with `GlobalKey<FormState>`
- Each field: `AppInputField`
- Date picker: `showDatePicker()` triggered from `AppInputField` with calendar icon
- Dropdowns: `DropdownButtonFormField` with Ochre theme styling
- All inside `SingleChildScrollView` → `AppSectionCard` wrapper

### 4.4 Student Attendance History
**File:** `lib/features/student/presentation/screens/student_detail_screen.dart`
(or `student_attendance_screen.dart` — confirm during task)

---

## Affected Files
| Action | File |
|---|---|
| MODIFY | `lib/features/student/presentation/screens/student_home_screen.dart` |
| MODIFY | `lib/features/student/presentation/screens/student_profile_screen.dart` |
| MODIFY | `lib/features/student/presentation/screens/student_edit_screen.dart` |
| MODIFY | `lib/features/student/presentation/screens/student_detail_screen.dart` |
| MODIFY | `lib/features/student/presentation/widgets/` — update any existing widgets |
