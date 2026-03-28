# Phase 2 - Student Management: Task Checklist (Logic Only)

> **Scope**: Repository data layer, BLoC/Cubit event handlers, use cases, Firestore indexes, and unit tests.
> No UI/widget code.

## P2-T1 - Fix Server-Side Search (Replace In-Memory Filter)
- [x] P2-T1.1 Add `nameLower` field write in `StudentDataRepository.addStudent()` - store `student.name.toLowerCase()`
- [x] P2-T1.2 Add `nameLower` field write in `StudentDataRepository.updateStudent()` - store `student.name.toLowerCase()`
- [x] P2-T1.3 Replace in-memory filter in `searchStudents()` (line ~121) with Firestore range query:
  ```dart
  .where('nameLower', isGreaterThanOrEqualTo: query.toLowerCase())
  .where('nameLower', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
  .orderBy('nameLower')
  .limit(pageSize)
  ```
- [x] P2-T1.4 Add composite index to `firestore.indexes.json`: collection `Students`, fields `nameLower ASC` + `isArchived ASC`
- [x] P2-T1.5 Unit test: `SearchStudentsUseCase` calls repo with server-side query; mock verifies correct Firestore arguments

## P2-T2 - Fix Pagination Cursor (`_hasReachedMax` logic)
- [x] P2-T2.1 Add `lastDocument: DocumentSnapshot?` field to `StudentDataState` (freezed or equatable)
- [x] P2-T2.2 In `_handleLoadMore` handler: call `.startAfterDocument(state.lastDocument)` instead of offset-based paging
- [x] P2-T2.3 Set `hasReachedMax = true` only when `result.length < pageSize`; never set it on live-stream emissions
- [x] P2-T2.4 Isolate paginated fetch cursor from real-time snapshot listener - cursor state must **not** reset when stream emits new data
- [x] P2-T2.5 Unit test: `_handleLoadMore` appends page 2 correctly and sets `hasReachedMax` on last page
- [x] P2-T2.6 Unit test: real-time stream emission does not reset `lastDocument` or `hasReachedMax`

## P2-T3 - Student Self-View Cubit
- [x] P2-T3.1 Create `lib/features/student/presentation/bloc/student_profile/student_profile_cubit.dart`
  - `load(String linkedUserId)` -> fetches student doc where `linkedUserId == uid`
  - States: `StudentProfileInitial`, `StudentProfileLoading`, `StudentProfileLoaded(StudentModel)`, `StudentProfileError(String)`
- [x] P2-T3.2 Register `StudentProfileCubit` in `GetIt` via `injection.dart`
- [x] P2-T3.3 Unit test: `load()` success emits `StudentProfileLoaded`; not-found emits `StudentProfileError`

## P2-T4 - Firestore Security Rule - Student Self-Read
- [x] P2-T4.1 Open `firestore.rules`
- [x] P2-T4.2 Add rule: student can read their own `Students/{studentId}` doc where `resource.data.linkedUserId == request.auth.uid`
- [x] P2-T4.3 Confirm existing admin/servant read rules are not broken

## P2-T5 - Final Gate
- [x] `flutter analyze` - 0 issues
- [x] `flutter test test/features/student/` - all pass
- [x] `firestore.indexes.json` has `nameLower` index entry
