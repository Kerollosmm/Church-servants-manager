# Phase 1: Core Blocs & Cubits Decomposition
**Scope**: Split all God Cubits/Blocs (>200 lines) before any UI work.
**Why First**: Every UI phase depends on a stable state management layer.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | 258 | Split into sub-use-cases |
| `lib/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart` | 429 | Extract load, save, filter logic |
| `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart` | 518 | Extract search, add, update, delete events |
| `lib/features/team/presentation/bloc/team_cubit.dart` | 255 | Extract member management logic |

---

## Step-by-Step Guide

### STEP 1 — Read & Annotate Each Bloc

Before touching code, read the file fully. For each method you find, write down:
- What it does (one-line)
- What layer it belongs to (domain / cubit / data)
- Whether it calls the repository or does computation itself

This mental model is required before any extraction.

---

### STEP 2 — auth_bloc.dart (258 lines)

**Goal**: Reduce auth_bloc.dart to an event dispatcher. Business logic goes to domain use cases.

1. Open `lib/features/auth/presentation/bloc/auth_bloc.dart`.
2. Identify the methods (likely: `_onLoginRequested`, `_onLogoutRequested`, `_onAuthStateChanged`, etc.).
3. For each method longer than ~20 lines, extract the body to a new file:
   - `lib/features/auth/domain/use_cases/sign_in_use_case.dart` — holds login orchestration
   - `lib/features/auth/domain/use_cases/sign_out_use_case.dart` — holds logout
   - `lib/features/auth/domain/use_cases/observe_auth_state_use_case.dart` — holds stream setup
4. Each use case is a simple class with a `call()` method.
5. Register the new use cases in GetIt (DI) in `lib/core/di/injection.dart`.
6. In auth_bloc.dart, inject the use cases via constructor and delegate to them.
7. Add `// FIX [P1]: extracted to auth_use_cases` to every changed line.

---

### STEP 3 — servant_data_cubit.dart (429 lines)

**Goal**: Reduce to a thin Cubit that emits state. Heavy logic goes to use cases and/or the repository.

1. Identify responsibilities: loading servants, filtering/searching, adding, updating, deleting.
2. Extraction targets:
   - `lib/features/servant/domain/use_cases/get_servants_use_case.dart`
   - `lib/features/servant/domain/use_cases/add_servant_use_case.dart`
   - `lib/features/servant/domain/use_cases/update_servant_use_case.dart`
   - `lib/features/servant/domain/use_cases/delete_servant_use_case.dart`
   - `lib/features/servant/domain/use_cases/filter_servants_use_case.dart` (if filtering is pure computation)
3. Register all in DI.
4. Update servant_data_cubit.dart to inject and delegate.

---

### STEP 4 — student_data_bloc.dart (518 lines)

**Goal**: The largest Bloc in the project. Same pattern.

1. Events likely: `StudentLoadRequested`, `StudentSearched`, `StudentAdded`, `StudentUpdated`, `StudentDeleted`.
2. Extraction targets:
   - `lib/features/student/domain/use_cases/get_students_use_case.dart`
   - `lib/features/student/domain/use_cases/search_students_use_case.dart`
   - `lib/features/student/domain/use_cases/add_student_use_case.dart`
   - `lib/features/student/domain/use_cases/update_student_use_case.dart`
   - `lib/features/student/domain/use_cases/delete_student_use_case.dart`
3. Register all in DI.
4. Update student_data_bloc.dart to inject and delegate.

---

### STEP 5 — team_cubit.dart (255 lines)

**Goal**: Separate team loading from team member management logic.

1. Split responsibilities:
   - `lib/features/team/domain/use_cases/get_teams_use_case.dart`
   - `lib/features/team/domain/use_cases/create_team_use_case.dart`
   - `lib/features/team/domain/use_cases/assign_servant_to_team_use_case.dart`
2. Register in DI.
3. Update team_cubit.dart to delegate.

---

### STEP 6 — Verify After Each Extraction

After each file is extracted:

```bash
flutter analyze
flutter test
```

Fix any import errors before continuing to the next file.

---

### STEP 7 — Final Phase 1 Verification

```bash
flutter analyze
flutter test
```

Manually launch the app:
- Sign in / sign out → verify auth still works.
- Navigate to servant list → verify data loads.
- Navigate to student list → verify data loads and search works.
- Navigate to team list → verify teams and members load.
