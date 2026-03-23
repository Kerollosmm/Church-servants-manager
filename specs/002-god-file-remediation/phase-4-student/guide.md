# Phase 4: Student Feature Decomposition
**Depends on**: Phase 1 complete (student_data_bloc.dart ≤150 lines)
**Scope**: 5 God files in the Student feature.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/student/presentation/screens/student_management_screen.dart` | 427 | Extract list item + filter bar + empty state |
| `lib/features/student/presentation/screens/student_edit_screen.dart` | 359 | Extract form to widget |
| `lib/features/student/presentation/screens/student_detail_screen.dart` | 262 | Extract detail sections |
| `lib/features/student/presentation/screens/student_profile_screen.dart` | 180 | Extract profile sections |
| `lib/features/student/presentation/widgets/student_edit_form_sections.dart` | 343 | Split into per-section widgets |

---

## Step-by-Step Guide

### STEP 1 — student_management_screen.dart (427 lines)

1. Extract the student list tile / card:
   - `lib/features/student/presentation/widgets/student_list_tile.dart`
2. Extract the search/filter bar:
   - `lib/features/student/presentation/widgets/student_search_bar.dart`
3. Extract empty state widget:
   - `lib/features/student/presentation/widgets/student_empty_state.dart`
4. Target: < 120 lines in the screen.

### STEP 2 — student_edit_form_sections.dart (343 lines)

> ⚠️ Fix this BEFORE fixing `student_edit_screen.dart` so the edit screen can use the cleaner form.

1. Identify major form sections (personal info, academic info, family contact, etc.).
2. Create per-section widgets:
   - `lib/features/student/presentation/widgets/student_personal_form.dart`
   - `lib/features/student/presentation/widgets/student_academic_form.dart`
   - `lib/features/student/presentation/widgets/student_contact_form.dart`
3. Make `student_edit_form_sections.dart` a thin composer (< 80 lines).

### STEP 3 — student_edit_screen.dart (359 lines)

1. After STEP 2, confirm the screen is already delegating to `student_edit_form_sections.dart`.
2. If not: extract the form body to use it.
3. Target: < 100 lines.

### STEP 4 — student_detail_screen.dart (262 lines)

1. Extract each card/section (attendance summary, personal bio, edit button row).
2. New widgets:
   - `lib/features/student/presentation/widgets/student_bio_section.dart`
   - `lib/features/student/presentation/widgets/student_attendance_summary.dart`
3. Target: < 80 lines.

### STEP 5 — student_profile_screen.dart (180 lines)

1. Extract profile card or header:
   - `lib/features/student/presentation/widgets/student_profile_header.dart`
2. Target: < 80 lines.

### STEP 6 — Verify

```bash
flutter analyze
flutter test
```

Manual: student list, search, filter, student detail, edit student, profile view.
