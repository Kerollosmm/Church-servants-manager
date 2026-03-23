# Phase 5 — Servant & Attendance Feature Screens

## Goal
Refactor all Servant and Attendance screens to match Stitch designs using Phase 1 shared components.

---

## Stitch References
| Screen | Stitch ID | Screenshot |
|---|---|---|
| Servant List | `369ea739c5fe49f294e7647b1d258b95` | [View](https://lh3.googleusercontent.com/aida/ADBb0ugUTn_p0VCUvmYMH9W-08sieVjhPsneR4G7KguNMpcKWjK0uUvMnbJ2KGPuDCqZ1GqDJMI-QYVH2-IT_yqJqhgfmZ9eCPUYR3wqOeSL8UHToqucZT6Lbzhv-gpFznMLqS0q6a7cWTA49Pg6tL0HRdEYanLYv-cHmD_Y2f6U6vxEv5luZ3bZNtz0x5h4_ltozybl3CTRzrZEJ7pFSM8XOodKum4z-_l0keEgUJ5R5E-FBVZDNyXeN0FyJL0) |
| Servant Profile Details | `16eff08817f8468da656204aa4b39c67` | [View](https://lh3.googleusercontent.com/aida/ADBb0uhbEzSRa0QqeP2-hW-0muXsUf5m1Gpc_9ISZ2gLKeyh_qkUc-IBwqKGoOp9AbMvB4z5RVVFAkp13Qp1rIio5lPwY1p8n2C0jfOKDp8ZaVqgdWYwJ-5olIxywCuBEVY1wYCExpHTr_2yIb6pcOY2WSWsegyipw4O6wDGSQCWNG0fZ_i4rGl7FtYbjproiOD_kPHN_6ioFxL6r-LKnjy9RusvVb2HxTr2Lyn4ZwiejNb0favDoGmIXXQW9AED) |
| Add/Edit Servant | `094981703451476e8e2f48aadd697881` | [View](https://lh3.googleusercontent.com/aida/ADBb0ujH5sqYJszw6IqokA97vNha8RA_1C0_2mf36yzJ5il89SyHQZhJUpw-8oli88DTv9L_AHxg0oNBitHmthlCMUQifRkW1VqP1dp5Wmt8On9up5hsnE6DmXf3fHd95YakVFFhh4dw_7PClHfFjt_EZbpfnbLYYC49vPPtSuwGIhRAIZPg-fIkwgsY9fQBFuP4xkUXzlGbdLO3zWBeSNRFGdeq60l6bKpWcy-sAxv8mCVpgy2yG1pvK9rWscs) |
| Attendance History | `097a7bd7e2ba4197b78d04cf2aad1bda` | [View](https://lh3.googleusercontent.com/aida/ADBb0uhenhnk0JvCJCyvl4qQ7KcAnbml4reoj8IDtgduuMAXjckKu7VgVVHWgG2q8o7B8Vt6DzBHxebBw9W1JIKpK45IwU44VOb09D1WVGUdZwMZ2fMAnce_mw_cIpcHqr0YYCl8KMkiaM4tu6t07JbpUFhTWjut0FzhHsjuS7-tf8db-V1UX7FPR2qkxUJxuBQnkCMkdWlEtN2xI0qDl3LGLv0f3HgFFgNxrEqOZGoenasoVtleqnBQBJPeB_o) |
| Create Attendance Session | `5cf6c91c4e2a4f389bd44c1f4596966b` | [View](https://lh3.googleusercontent.com/aida/ADBb0ujGtHZLSGz154_Y9hr6isF31sbCaZZdcErUFsXDNKwPgiuqgAYs2MPl6tx3ukYmFWI4qYcGSbEqquDqLxVuzEL5VY3FU-xFbQyHw4iOh9njfOtDIPlfjZEYsPEj8TZkkt7oNIhhYanDhecBoKl6URtFFO3zVsyDFnvJSU53Tfti38Q61NR0lmhUnywpuCTH5LyZ-HlbVF50CdG-JCKvshHsmcdrmlcoeOoJPYp4gdm1897eG_ZCEkEtPXT0) |
| Attendance Taking | `5f7e0aa247de40e6abb4513ce806e99a` | [View](https://lh3.googleusercontent.com/aida/ADBb0uimgA7BdY-_uWyQr7Q-dxmBr5tgj3Gs2TDUZPcmblPjjZQR1gbG962VI15Ax47Tjf1QrHHIBSfEee9Xq9Z-mrIId5bnvV67hrHvxmN0WruoWsVy4xAUet0Zr1iKMwPICKATYL9hh-YutdJVtl_Gfx_cOxg1N445qoshXCkmSMPNeOEQiJ0Hduum9YbANKjJGNrL6eBByRoQzAOW8Re-RvgzktgUv-qHkHCMn96o1LhVHljJl-CWrLYePcA-) |

---

## Screen Designs

### Servant List
- Mirrors Student List pattern (Phase 4 reference)
- `AppHeader` with "الخدام" title + servant count
- `AppSearchBar` to filter by name
- `AppPrimaryButton` "إضافة خادم"
- `ListView.builder` with `AppPersonListTile`:
  - Avatar, name, assigned group, student count badge
  - Tap → Servant Profile

### Servant Profile Details
- Same structure as Student Profile (Phase 4 Section 4.2)
- Hero header: avatar (radius 48), name, role/title
- Info section: `AppSectionCard` with `AppInfoRow` (Phone, Email, Joined date, Team)
- My Students section: `AppSectionCard` with list of assigned students (first 5 + "see all")
- My Sessions: `AppSectionCard` with last 3 attendance sessions
- Action row: Edit + Remove from team

### Add/Edit Servant
- Same pattern as Add/Edit Student (Phase 4 Section 4.3)
- Fields: Name, Phone, Email, Role, Assigned Group
- Avatar picker at top

### Attendance History (Admin view)
- `AppHeader` with "سجل الحضور"
- Filter chips row: All / This Week / This Month / Custom (stickily below header)
- `ListView.builder` with session cards:
  - Each card: `AppSectionCard` compact — date, session name, counts (present/absent)
  - Tap → view session details
- Pull-to-refresh: `RefreshIndicator`

### Create Attendance Session
- `AppHeader` with "جلسة جديدة"
- `AppSectionCard` form:
  - `AppInputField` for session name/title
  - Date picker: `AppInputField` read-only → `showDatePicker()`
  - Group/Team selector: `DropdownButtonFormField`
  - Notes: multi-line `AppInputField` (maxLines: 3)
- `AppPrimaryButton(label: 'ابدأ الجلسة')` — navigates to Attendance Taking

### Attendance Taking
- Active session header: `AppHeader` with session title + date
- **Attendance count bar** at top: present x / total y (ochre progress bar)
- `ListView.builder` of all students in group:
  - Each row: `AppPersonListTile` with 3-state toggle at trailing:
    - Tap cycles: حاضر (green check) → غائب (red x) → معذور (orange minus)
    - State tracked locally before save
- `AppPrimaryButton(label: 'حفظ الجلسة')` sticky at bottom
- Optimistic UI: state updates instantly, saves on session save

---

## Implementation Plan

### 5.1 Servant Screens
Follows exact same pattern as Phase 4. Files:
- `lib/features/servant/presentation/screens/servant_list_screen.dart`
- `lib/features/servant/presentation/screens/servant_detail_screen.dart`
- `lib/features/servant/presentation/screens/add_edit_servant_screen.dart`

### 5.2 Attendance History
**File:** `lib/features/attendance/presentation/screens/attendance_history_screen.dart`

```dart
class AttendanceHistoryScreen extends StatelessWidget {
  Widget build(context) => AppScreenShell(
    appBar: AppHeader(title: 'سجل الحضور'),
    body: Column(children: [
      const _FilterChipsRow(),
      Expanded(child: _SessionList()),
    ]),
  );
}

class _FilterChipsRow extends StatelessWidget {
  // FilterChip row: All / هذا الأسبوع / هذا الشهر
  // Uses ChoiceChip with Ochre selected color
}

class _SessionList extends StatelessWidget {
  // ListView.builder + RefreshIndicator
  // Each: _SessionCard (AppSectionCard compact)
}
```

### 5.3 Create Attendance Session
**File:** `lib/features/attendance/presentation/screens/attendance_session_create_screen.dart`

```dart
class AttendanceSessionCreateScreen extends StatelessWidget {
  Widget build(context) => AppScreenShell(
    appBar: AppHeader(title: 'جلسة جديدة'),
    body: SingleChildScrollView(
      child: AppSectionCard(
        child: Form(
          key: _formKey,
          child: Column(children: [
            _SessionNameField(),
            _DatePickerField(),
            _GroupDropdown(),
            _NotesField(),
            _CreateButton(),
          ]),
        ),
      ),
    ),
  );
}
```

### 5.4 Attendance Taking
**File:** `lib/features/attendance/presentation/screens/attendance_taking_screen.dart`

```dart
class AttendanceTakingScreen extends StatelessWidget {
  Widget build(context) => AppScreenShell(
    appBar: AppHeader(title: sessionTitle, subtitle: dateFormatted),
    body: Column(children: [
      _AttendanceProgressBar(present: present, total: total),
      Expanded(child: _StudentAttendanceList(students: students)),
    ]),
    bottomNavigationBar: _SaveSessionButton(),
  );
}

class _StudentAttendanceList extends StatelessWidget {
  // ListView.builder → _AttendanceTile
}

class _AttendanceTile extends StatelessWidget {
  // AppPersonListTile + trailing: _AttendanceToggle
}

class _AttendanceToggle extends StatefulWidget {
  // GestureDetector cycling between 3 states
  // Uses ValueNotifier<AttendanceStatus> locally
  // Dispatches event to bloc on change
}
```

---

## Affected Files
| Action | File |
|---|---|
| MODIFY | `lib/features/servant/presentation/screens/servant_list_screen.dart` |
| MODIFY | `lib/features/servant/presentation/screens/servant_detail_screen.dart` |
| MODIFY | `lib/features/servant/presentation/screens/add_edit_servant_screen.dart` |
| MODIFY | `lib/features/attendance/presentation/screens/attendance_history_screen.dart` |
| MODIFY | `lib/features/attendance/presentation/screens/attendance_session_create_screen.dart` |
| MODIFY | `lib/features/attendance/presentation/screens/attendance_taking_screen.dart` |
| MODIFY | `lib/features/attendance/presentation/screens/student_attendance_screen.dart` |
