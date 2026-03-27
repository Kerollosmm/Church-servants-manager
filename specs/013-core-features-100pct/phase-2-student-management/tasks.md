# Phase 2 — Student Management: Task Checklist

## P2-T1 · Fix Server-Side Search
- [ ] P2-T1.1 Add `nameLower` field write in `StudentDataRepository.addStudent()` and `updateStudent()` (store `name.toLowerCase()`)
- [ ] P2-T1.2 Replace in-memory filter in `searchStudents()` with Firestore range query on `nameLower`
- [ ] P2-T1.3 Add index to `firestore.indexes.json`: `Students` / `nameLower ASC`
- [ ] P2-T1.4 Unit test: `SearchStudentsUseCase` returns server-filtered results (mock repo)

## P2-T2 · Fix Pagination Cursor (`_hasReachedMax`)
- [ ] P2-T2.1 Add `lastDocument: DocumentSnapshot?` to `StudentDataState`
- [ ] P2-T2.2 In `_handleLoadMore`: use `.startAfterDocument(state.lastDocument)` for page 2+
- [ ] P2-T2.3 Set `hasReachedMax = true` only when `result.length < pageSize`
- [ ] P2-T2.4 Keep real-time listener stream separate from paginated fetch cursor
- [ ] P2-T2.5 Unit test: second page request returns correct cursor, max flag set properly

## P2-T3 · Student Widget Atoms
- [ ] P2-T3.1 Create `student_list_tile.dart` — avatar, name, class chip, archived badge
- [ ] P2-T3.2 Create `student_search_bar.dart` — debounced TextField dispatching `StudentEventSearch`
- [ ] P2-T3.3 Create `student_empty_state.dart` — illustration + message variants (empty list / no results)
- [ ] P2-T3.4 Create `student_detail_card.dart` — fields: name, phone, parent phone, team, linked status
- [ ] P2-T3.5 Create `student_form.dart` — name / phone / parent phone / team dropdown / linked UID (admin only)

## P2-T4 · Implement StudentManagementScreen
- [ ] P2-T4.1 `AppBar` with title + search toggle
- [ ] P2-T4.2 `BlocBuilder` → `StudentDataSuccess`: `ListView.builder` with `StudentListTile`
- [ ] P2-T4.3 `BlocBuilder` → `StudentDataLoading`: shimmer or `CircularProgressIndicator`
- [ ] P2-T4.4 `BlocBuilder` → `StudentDataFailure`: error message + retry button
- [ ] P2-T4.5 Infinite scroll: `ScrollController` at 80% → dispatch `StudentEventLoadMore`
- [ ] P2-T4.6 FAB → push `/student/edit` with null args (add mode)
- [ ] P2-T4.7 Swipe on tile → dispatch `StudentEventDelete` (soft archive) with undo `SnackBar`
- [ ] P2-T4.8 Widget test: list renders students, empty state shown when list empty

## P2-T5 · Implement StudentDetailScreen
- [ ] P2-T5.1 `StudentDetailCard` showing all fields
- [ ] P2-T5.2 Edit `IconButton` in `AppBar` → push `/student/edit` with `StudentEditArgs`
- [ ] P2-T5.3 "Attendance History" `ListTile` → push `/student-attendance` with `StudentAttendanceArgs`
- [ ] P2-T5.4 Archive/restore toggle (admin only)
- [ ] P2-T5.5 Widget test: displays student name + fields from args

## P2-T6 · Implement StudentEditScreen (Add & Edit)
- [ ] P2-T6.1 Render `StudentForm` with `args.initialData` (null = add)
- [ ] P2-T6.2 On save: dispatch `StudentEventAdd` or `StudentEventUpdate`
- [ ] P2-T6.3 `BlocListener` on success → pop + `SnackBar`
- [ ] P2-T6.4 `BlocListener` on failure → inline error banner
- [ ] P2-T6.5 Widget test: form submit dispatches correct event

## P2-T7 · Implement StudentHomeScreen (Student Role)
- [ ] P2-T7.1 Receive `AuthUser` from `RoleRouter.resolve()`
- [ ] P2-T7.2 Show greeting card + quick-links: "My Profile", "My Attendance"
- [ ] P2-T7.3 Widget test: renders greeting for student role

## P2-T8 · Implement StudentProfileScreen (Student Self-View)
- [ ] P2-T8.1 Create `StudentProfileCubit` that fetches student doc by `linkedUserId`
- [ ] P2-T8.2 Register `StudentProfileCubit` in `GetIt`
- [ ] P2-T8.3 `StudentProfileScreen` provides cubit via `BlocProvider`
- [ ] P2-T8.4 `BlocBuilder` → loaded: show `StudentDetailCard` (read-only)
- [ ] P2-T8.5 Widget test: shows loading then profile data

## P2-T9 · Final Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/student/` — all pass
- [ ] Manual smoke: admin can add/edit/archive student; student can view own profile
- [ ] Search returns server results in < 800ms on emulator
