# Phase 2 — Student Management (60% → 100%)

## Goal
Rebuild the student presentation layer on top of the already-solid `StudentDataBloc` + repository + use-case stack. Replace blank screens with real UI, fix the in-memory search limitation, and correct the pagination/stream boundary so `_hasReachedMax` is accurate.

## Existing Assets (keep, do not rewrite)
- `StudentDataBloc` with all event handlers in `student_data_bloc_handlers.dart`
- `StudentDataRepository` — Firestore CRUD + query service
- All use cases: `GetStudentsUseCase`, `SearchStudentsUseCase`, `AddStudentUseCase`, `UpdateStudentUseCase`, `DeleteStudentUseCase`, `RestoreStudentUseCase`
- `StudentLinkedUserSyncService` — UID/profile sync
- `AppRouter` wraps student routes in `_withStudentDataBloc` provider

## What Is Missing / Broken
1. `StudentManagementScreen` — blank (`Text('StudentManagementScreen - Blanked')`)
2. `StudentDetailScreen` — blank
3. `StudentEditScreen` — blank
4. `StudentHomeScreen` — blank (student self-view)
5. `StudentProfileScreen` — blank (student self-profile)
6. **Server-side search** — `student_data_repository.dart:121` does client-side `where` filter after fetching all docs; replace with Firestore `startAt`/`endAt` name-range query or dedicated indexed query path.
7. **Pagination `_hasReachedMax`** — `student_data_bloc_handlers.dart:175` resets max flag incorrectly on live-stream merge; decouple paginated fetch from real-time stream.

## Architecture Decisions
- `StudentManagementScreen` uses `BlocBuilder<StudentDataBloc>` for list rendering.
- Search bar dispatches `StudentEventSearch` debounced 300ms.
- Infinite scroll: `ScrollController` listener dispatches `StudentEventLoadMore`.
- `StudentDetailScreen` receives `StudentDetailArgs` (existing); reads from bloc state — no direct repo call.
- `StudentEditScreen` receives `StudentEditArgs`; dispatches `StudentEventAdd` or `StudentEventUpdate`.
- `StudentHomeScreen` / `StudentProfileScreen` are student-role views — read-only, show own student doc fetched by linked UID.

## Server-Side Search Fix
Replace in-memory filter in `StudentDataRepository.searchStudents()`:
```
Old: fetch all → client-side filter
New: Firestore composite query:
     .where('name', isGreaterThanOrEqualTo: query)
     .where('name', isLessThanOrEqualTo: query + '\uf8ff')
     .orderBy('name')
     .limit(pageSize)
```
Requires Firestore index: `students` collection, field `name` ASC + `classId` ASC (if filtered).

## Pagination Fix
`_hasReachedMax` must be set per-query cursor, not reset on every stream emission. Separate `_StudentPaginatedFetcher` helper isolates cursor state from the real-time listener.

## Files to Create / Modify

### New Widgets (create)
- `lib/features/student/presentation/widgets/student_list_tile.dart`
- `lib/features/student/presentation/widgets/student_search_bar.dart`
- `lib/features/student/presentation/widgets/student_empty_state.dart`
- `lib/features/student/presentation/widgets/student_form.dart` — shared add/edit form
- `lib/features/student/presentation/widgets/student_detail_card.dart`

### Screens to Implement (replace blanks)
- `student_management_screen.dart` — list + search + FAB add + swipe-to-archive
- `student_detail_screen.dart` — profile card + edit button + attendance link
- `student_edit_screen.dart` — form (add & edit mode)
- `student_home_screen.dart` — student-role home with dashboard links
- `student_profile_screen.dart` — student self-profile (read-only)

### Data Layer Fixes
- `lib/features/student/data/repos/student_data_repository.dart` — replace in-memory search with server query
- `lib/features/student/presentation/bloc/student_data/student_data_bloc_handlers.dart` — fix `_hasReachedMax` cursor logic

### Test Fixes
- `test/features/student/domain/usecases/get_students_usecase_test.dart` — verify pagination cursor tests pass with fix

## UI Design Reference
- `UI Screens/student_list/`
- `UI Screens/student_profile_details/`
- `UI Screens/add_edit_student/`

## Completion Gate
- [ ] `flutter analyze` passes
- [ ] All 5 student screens render with real data
- [ ] Search returns server-filtered results
- [ ] Pagination reaches max correctly (no ghost reload)
- [ ] Admin can add/edit/archive; student can view own profile
- [ ] `flutter test test/features/student/` passes
