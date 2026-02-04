# Application Issues & Technical Debt

This document tracks identified bugs, performance bottlenecks, and architectural issues in the current implementation.

## 🔴 High Severity

### 1. Potential Runtime Crash in `StudentDataRepository`
- **File:** `lib/features/student/data/repos/student_data_repository.dart`
- **Status:** ✅ **FIXED**
- **Resolution:** Verified `QueryDocumentSnapshot.data()` is non-nullable. Cleaned up access logic.

### 2. Inefficient Client-Side Filtering
- **File:** `lib/features/student/data/services/role_based_student_service.dart`
- **Status:** ✅ **FIXED**
- **Resolution:** Implemented `getStudentsByGroup` in repository and updated service to use server-side filtering.

## 🟡 Medium Severity

### 1. Incomplete `AuthUser` Equality
- **File:** `lib/core/models/auth_user.dart`
- **Status:** ✅ **FIXED**
- **Resolution:** Included `role` and `groupId` in `==` and `hashCode`.

### 2. Side-Effects in Read-Only BLoC Event
- **File:** `lib/features/student/presentation/bloc/student_profile/student_profile_bloc.dart`
- **Issue:** `StudentProfileLoadRequested` triggers a Firestore write (upsert) if the profile is missing.
- **Risk:** Violates separation of concerns. Makes debugging harder as "loading" data can change the state of the database.
- **Fix:** Move profile creation to the registration flow or a dedicated `StudentProfileCreateRequested` event.

### 3. Inefficient Fallback Logic
- **File:** `lib/features/student/data/repos/student_data_repository.dart`
- **Issue:** `getStudentsByClass` uses a `whereIn` fallback with chunking.
- **Risk:** While safe, it's slow. It indicates that the `classId` field on student documents is not reliably populated.
- **Fix:** Ensure `classId` is always set during student creation/migration and remove the fallback.

## 🟢 Low Severity

### 1. Redundant Data Storage
- **File:** `lib/core/utils/data_seeder.dart`
- **Issue:** `assignMeAsStudentAndCreateProfile` writes identical data to both `Students` and `Users` collections.
- **Risk:** Data synchronization issues. If one document is updated and the other isn't, the app state becomes inconsistent.
- **Fix:** Use a single source of truth or implement Firestore Triggers to keep them in sync.