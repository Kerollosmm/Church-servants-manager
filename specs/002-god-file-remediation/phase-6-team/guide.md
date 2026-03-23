# Phase 6: Team Feature Decomposition
**Depends on**: Phase 1 complete (team_cubit.dart ≤120 lines)
**Scope**: 3 God files in the Team feature.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/team/presentation/screens/team_management_screen.dart` | 397 | Extract list tile + action menu |
| `lib/features/team/presentation/screens/team_members_screen.dart` | 197 | Extract member row widget |
| `lib/features/team/presentation/widgets/assign_servant_dialog.dart` | 189 | Extract servant picker list |

---

## Step-by-Step Guide

### STEP 1 — team_management_screen.dart (397 lines)

1. Identify the **team card / list tile**:
   - Extract to: `lib/features/team/presentation/widgets/team_list_tile.dart`
2. Identify the **team action menu or FAB row**:
   - Extract to: `lib/features/team/presentation/widgets/team_action_row.dart` (if > 30 lines)
3. Identify any **empty state**:
   - Extract to: `lib/features/team/presentation/widgets/team_empty_state.dart`
4. Target: < 100 lines.

### STEP 2 — team_members_screen.dart (197 lines)

1. Identify the **member row** (each servant listed as a team member):
   - Extract to: `lib/features/team/presentation/widgets/team_member_tile.dart`
2. Target: < 80 lines.

### STEP 3 — assign_servant_dialog.dart (189 lines)

1. Identify the **servant picker list** (a scrollable list of servants to choose from):
   - Extract to: `lib/features/team/presentation/widgets/servant_picker_list.dart`
2. The dialog file itself becomes a thin wrapper.
3. Target: < 80 lines.

### STEP 4 — Verify

```bash
flutter analyze
flutter test
```

Manual: view team list, add team, open team members, assign servant to team via dialog.
