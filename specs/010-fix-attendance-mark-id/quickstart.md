# Quickstart: Fix Attendance Mark Document ID

## Goal

Implement and verify the attendance mark identity fix so repeated marking for the same student and session updates a single canonical record.

## Steps

1. Confirm the mark write path in `lib/features/attendance/data/repos/attendance_repository.dart` still resolves mark documents by `studentId` and retains merge-based updates.
2. Locate the local attendance persistence model used for mark records, if present in the current codebase, and align its `recordId` with `studentId`.
3. Preserve unique generated IDs only for queue correlation records, not for attendance business records.
4. Add or update repository tests to verify repeated marking for the same student and session leaves exactly one mark document with the `studentId` document key.
5. Add targeted regression coverage for any local record identity mapping touched during implementation.
6. Verify that `AttendanceTakingCubit` behavior remains unchanged by running the relevant attendance repository and presentation tests.

## Verification Commands

```bash
flutter test test/features/attendance/data/repos/attendance_repository_test.dart
flutter analyze
```

## Conditional Commands

Run code generation only if implementation changes a generated model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Expected Outcome

- One mark document per student per session
- Re-marking updates instead of duplicating
- Attendance-taking UI states remain stable
- Queue correlation IDs remain unique and separate from attendance business IDs
