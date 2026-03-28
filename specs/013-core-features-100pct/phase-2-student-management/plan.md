# Phase 2 — Student Management (Logic Only)

## Goal
Fix the two data-layer bugs that undermine student management correctness: in-memory search (which breaks on large datasets) and the `_hasReachedMax` pagination flag (which resets incorrectly on live-stream emissions). Also add the student self-view cubit and Firestore self-read rule.

## Existing Assets (keep, do not rewrite)
- `StudentDataBloc` + all use cases — working
- `StudentDataRepository` — CRUD intact; only `searchStudents` path changes
- `StudentLinkedUserSyncService` — untouched
- `AppRouter._withStudentDataBloc` — untouched

## What Is Being Fixed (Logic Only)

### 1. Server-Side Search
- `StudentDataRepository.searchStudents()` currently fetches all documents and filters in memory
- Replace with Firestore range query on a `nameLower` field (sorted, prefix-matchable)
- `addStudent`/`updateStudent` must write `nameLower = name.toLowerCase()` on every save
- New Firestore index required in `firestore.indexes.json`

### 2. Pagination Cursor (`_hasReachedMax`)
- Current bug: `lastDocument` (cursor) is reset whenever the real-time snapshot listener emits
- Fix: store `lastDocument: DocumentSnapshot?` in `StudentDataState`; load-more handler uses `.startAfterDocument(lastDocument)` 
- `hasReachedMax` is set only when a page returns fewer docs than `pageSize`
- Real-time stream emissions must not touch cursor or `hasReachedMax`

### 3. Student Self-View Cubit (new)
- `StudentProfileCubit` — fetches student doc by `linkedUserId`
- Registered in `GetIt`
- States: Initial → Loading → Loaded(StudentModel) → Error

### 4. Firestore Self-Read Rule
- Student can read their own `Students/{studentId}` doc where `resource.data.linkedUserId == request.auth.uid`

## Files Changed (Logic Only)
| File | Change |
|------|--------|
| `lib/features/student/data/repos/student_data_repository.dart` | server-side search + `nameLower` write |
| `lib/features/student/presentation/bloc/student_data/student_data_bloc_handlers.dart` | pagination cursor fix |
| `lib/features/student/presentation/bloc/student_data/student_data_state.dart` | add `lastDocument` field |
| `lib/features/student/presentation/bloc/student_profile/student_profile_cubit.dart` | NEW |
| `lib/core/di/injection.dart` | register `StudentProfileCubit` |
| `firestore.indexes.json` | `nameLower ASC` index |
| `firestore.rules` | student self-read rule |

## Completion Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/student/` — all pass
- [ ] `firestore.indexes.json` updated with `nameLower` index
