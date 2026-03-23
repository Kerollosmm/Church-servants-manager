# Phase 5: Attendance Feature Decomposition
**Depends on**: Phase 1 complete (attendance cubits stable)
**Scope**: 4 God files in the Attendance feature.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/attendance/presentation/screens/attendance_history_screen.dart` | 484 | 🔴 Largest screen — extract list, filter, header |
| `lib/features/attendance/presentation/screens/attendance_taking_screen.dart` | 350 | Extract student row widget + action buttons |
| `lib/features/attendance/presentation/screens/attendance_session_create_screen.dart` | 326 | Extract form to widget |
| `lib/features/attendance/presentation/screens/student_attendance_screen.dart` | 223 | Extract chart/summary sections |

---

## Step-by-Step Guide

### STEP 1 — attendance_history_screen.dart (484 lines) ⚠️ Priority

This is the heaviest UI screen in the project. Treat with extra care.

1. Identify the **session list tile** (what is rendered for each session in the list):
   - Extract to: `lib/features/attendance/presentation/widgets/session_list_tile.dart`
2. Identify the **filter bar** (date range, team filter, etc.):
   - Extract to: `lib/features/attendance/presentation/widgets/attendance_filter_bar.dart`
3. Identify the **statistics header** (summary counts at the top):
   - Extract to: `lib/features/attendance/presentation/widgets/attendance_stats_header.dart`
4. Identify the **empty state** widget:
   - Extract to: `lib/features/attendance/presentation/widgets/attendance_empty_state.dart`
5. Target: < 120 lines for the screen.

### STEP 2 — attendance_taking_screen.dart (350 lines)

1. Identify the **student attendance row** (each student row with present/absent toggles):
   - Extract to: `lib/features/attendance/presentation/widgets/attendance_student_row.dart`
2. Identify the **session header info** (session name, date, team):
   - Extract to: `lib/features/attendance/presentation/widgets/attendance_session_header.dart`
3. Target: < 100 lines.

### STEP 3 — attendance_session_create_screen.dart (326 lines)

1. Identify the form fields (session name, date, team picker):
   - Extract to: `lib/features/attendance/presentation/widgets/session_create_form.dart`
2. Target: < 80 lines.

### STEP 4 — student_attendance_screen.dart (223 lines)

1. Identify summary/chart widgets (individual student's attendance percentage, visual bar):
   - Extract to: `lib/features/attendance/presentation/widgets/student_attendance_chart.dart`
2. Target: < 80 lines.

### STEP 5 — Verify

```bash
flutter analyze
flutter test
```

Manual: open attendance history, create a session, take attendance for a student, view student attendance screen.
