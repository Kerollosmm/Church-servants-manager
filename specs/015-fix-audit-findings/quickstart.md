# Quickstart: Production Audit Remediation

## Goal

Implement and verify the audited production fixes for attendance, session lifecycle, authorization refresh, restored-account security, linked-student integrity, and privileged admin safeguards while excluding offline sync work.

## Implementation Order

1. Harden attendance write correctness in `lib/Features/attendance/data/repos/`.
2. Update attendance session admin flow and permission-refresh handling in `lib/Features/attendance/presentation/` and auth flow files.
3. Add or update additive attendance read models and their consumers.
4. Fix student linkage, assignment dual-write consistency, and search/link readiness.
5. Update `firestore.rules` and rule tests.
6. Update `functions/src/` callable authorization, self-archive guard, lifecycle timestamps, and related tests or validation.

## Expected File Areas

- `lib/Features/attendance/data/repos/attendance_repository.dart`
- `lib/Features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`
- `lib/Features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart`
- `lib/Features/auth/data/services/firebase_auth_provider.dart`
- `lib/Features/auth/domain/usecases/observe_auth_state_usecase.dart`
- `lib/core/routing/role_router.dart`
- `lib/Features/student/data/repos/student_data_repository.dart`
- `lib/Features/student/data/services/student_linked_user_sync_service.dart`
- `lib/Features/admin/data/admin_team_service.dart`
- `functions/src/index.ts`
- `functions/src/lifecycle_helpers.ts`
- `firestore.rules`

## Verification Commands

### Flutter

```powershell
flutter test
```

### Focused Rule And Feature Tests

```powershell
flutter test test/core/firestore/access_rules_test.dart
flutter test test/features/attendance/data/repos/attendance_repository_test.dart
flutter test test/features/auth/domain/usecases/observe_auth_state_usecase_test.dart
flutter test test/features/auth/data/services/admin_user_provisioning_service_test.dart
flutter test test/features/team/data/repos/team_repository_test.dart
```

### Cloud Functions

```powershell
npm --prefix functions run lint
npm --prefix functions run build
```

### Code Generation

Run only if any `freezed` or `json_serializable` model changes:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Acceptance Checklist

- Attendance create/update/clear produces committed audit records only on success.
- Permission-denied attendance actions show an access-changed message and refresh the signed-in user state.
- Duplicate session creation is blocked without relying on a non-atomic pre-check.
- Authorized servants/admins can close sessions early, and expired/closed sessions no longer appear active.
- Bulk mark remaining students works for large teams without partial results.
- Student history and summary screens use the new bounded/scalable read path.
- Restored privileged users are forced through password change before normal navigation.
- Admin self-archive is rejected.
- Newly created linked students are searchable and immediately readable only by the linked account.

## Implementation Notes

- Preserve existing document fields and add only backward-compatible documents/fields.
- Keep both `assignedTeamIds` and `assignedTeamId` synchronized during all assignment writes.
- Add `FIX [015]` comments beside changed production logic to satisfy the constitution.
