# Quickstart: Pre-Deploy Security & Stability Fixes

**Branch**: `004-security-stability-fixes` | **Date**: 2026-03-22

This guide walks you through applying and verifying all 7 fixes from the pre-deployment
audit. Follow steps in order — security fixes first.

---

## Prerequisites

- Flutter SDK installed and `flutter doctor` clean
- Firebase CLI installed: `npm install -g firebase-tools`
- Firebase project authenticated: `firebase login`
- Firebase Emulator Suite: `firebase emulators:start --only firestore`

---

## Step 1: Apply All Code Fixes

Run `flutter analyze` first to establish a baseline:
```bash
flutter analyze
```

Apply the code changes per [plan.md](plan.md) — Fix Groups A, B, C, D:
- `firestore.rules` (new)
- `firestore.indexes.json` (new)
- `.gitattributes` (new)
- `lib/core/routing/app_router.dart`
- `lib/features/auth/data/services/firebase_auth_provider.dart`
- `lib/features/attendance/data/repos/attendance_repository.dart`
- `lib/features/student/domain/repos/i_student_repository.dart`
- `lib/features/student/domain/usecases/delete_student_usecase.dart`
- `lib/features/student/domain/usecases/restore_student_usecase.dart`
- `lib/features/student/data/repos/student_data_repository.dart`
- `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`

---

## Step 2: Verify Static Analysis

```bash
flutter analyze
# Expected: No issues found!

dart run build_runner build --delete-conflicting-outputs
# Expected: No conflicts
```

---

## Step 3: Test Firestore Rules (Emulator)

```bash
# Start emulator
firebase emulators:start --only firestore

# Verify manually via Emulator UI at http://127.0.0.1:4000
# Test scenarios:
# 1. Sign in as admin → create attendance session → SHOULD SUCCEED
# 2. Sign in as servant → create attendance session → SHOULD FAIL (permission-denied)
# 3. Sign in as servant (assigned to team X) → write mark for team X → SHOULD SUCCEED
# 4. Sign in as servant → write mark for team Y (not assigned) → SHOULD FAIL
# 5. Sign in as student → delete a student doc → SHOULD FAIL
```

---

## Step 4: Verify Archive/Restore Actor Identity

```bash
# 1. Run the app on emulator
# 2. Sign in as admin
# 3. Archive a student
# 4. Check Firestore emulator UI → Students/{docId}
# Expected: archivedByUserId = <admin's uid> (NOT 'system')
```

---

## Step 5: Verify Logout Idempotency

In the Flutter app or a Dart test:
```dart
// Call logout twice — second call must NOT throw
await firebaseAuthProvider.logOut();
await firebaseAuthProvider.logOut(); // should complete silently
```

---

## Step 6: Deploy to Production

Only after all steps above pass:
```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes

# Tag the release
git tag v1.0.0-security-patch

# Build release APK
flutter build apk --release
```

---

## Rollback

If rules deployment causes issues:
```bash
# Revert to previous rules version in Firebase Console
# → Firestore → Rules → History → Restore previous version
```
