# Phase 3: Servant Feature Decomposition
**Depends on**: Phase 1 complete (servant_data_cubit.dart ≤150 lines)
**Scope**: 5 God files in the Servant feature.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/servant/presentation/screens/servant_list_screen.dart` | 367 | Extract list item widget + filter bar |
| `lib/features/servant/presentation/screens/servant_detail_screen.dart` | 219 | Extract detail sections as sub-widgets |
| `lib/features/servant/presentation/screens/servant_dashboard_screen.dart` | 216 | Extract stat card widgets |
| `lib/features/servant/presentation/screens/add_edit_servant_screen.dart` | 233 | Extract form to `servant_edit_form_sections.dart` (already exists, refactor) |
| `lib/features/servant/presentation/widgets/servant_edit_form_sections.dart` | 196 | Split into per-section widgets |

---

## Step-by-Step Guide

### STEP 1 — servant_list_screen.dart (367 lines)

1. Identify the list item widget (the card/row rendered per servant).
   - Extract to: `lib/features/servant/presentation/widgets/servant_list_tile.dart`
2. Identify the search bar / filter row at the top.
   - Extract to: `lib/features/servant/presentation/widgets/servant_search_bar.dart`
3. Replace in `servant_list_screen.dart`. Target: < 120 lines.

### STEP 2 — servant_detail_screen.dart (219 lines)

1. Identify each "section" (personal info, attendance history, team assignment, etc.).
2. Extract each section to:
   - `lib/features/servant/presentation/widgets/servant_info_section.dart`
   - `lib/features/servant/presentation/widgets/servant_team_section.dart`
   - Other sections similarly named.
3. Target: < 80 lines for the screen.

### STEP 3 — servant_dashboard_screen.dart (216 lines)

1. Identify stat cards / summary tiles.
2. Extract to: `lib/features/servant/presentation/widgets/servant_stat_card.dart`
3. Target: < 80 lines for the screen.

### STEP 4 — add_edit_servant_screen.dart (233 lines)

1. Confirm whether it's already delegating to `servant_edit_form_sections.dart`.
2. If not: extract the form body to `servant_edit_form_sections.dart`.
3. Target: < 80 lines for the screen.

### STEP 5 — servant_edit_form_sections.dart (196 lines)

1. This file likely has multiple form sections stitched together.
2. Extract each major section (e.g., personal info fields, contact fields) into its own sub-widget.
   - `lib/features/servant/presentation/widgets/servant_personal_info_form.dart`
   - `lib/features/servant/presentation/widgets/servant_contact_form.dart`
3. `servant_edit_form_sections.dart` becomes a composer widget < 80 lines.

### STEP 6 — Verify

```bash
flutter analyze
flutter test
```

Manual: Navigate to Servant List, Detail, Dashboard, and Add/Edit screens. Verify all UI and form behavior preserves.
