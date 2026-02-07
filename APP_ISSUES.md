# Application Issues & Technical Debt

This document tracks identified bugs, performance bottlenecks, and architectural issues in the current implementation.

## 🔴 High Severity

### 1. Missing Role-Based Permission Check in Servant Search
- **Status:** ✅ Fixed
- **Fix:** Added role check in `_onServantsSearchRequested` in `ServantDataBloc`.

### 2. Performance Bottleneck: Sequential Firestore Queries
- **File:** `lib/features/student/data/repos/student_data_repository.dart`
- **Issue:** `getStudentsByClass` (fallback logic) executes `await` inside a loop for chunked ID lookups.
- **Risk:** Linear increase in latency based on class size (N/10 queries). Creates an "async waterfall".
- **Fix:** Use `Future.wait` to execute chunked queries in parallel.

### 3. Potential Race Condition in Auth State Changes
- **File:** `lib/features/auth/data/services/firebase_auth_provider.dart`
- **Issue:** `authStateChanges` uses `asyncMap` to fetch user data.
- **Risk:** Rapid authentication state changes (e.g., login -> logout) could lead to out-of-order data delivery or UI flickers if Firestore lookups resolve out of sequence.
- **Fix:** Use `switchMap` (from `rxdart`) or implement a synchronization mechanism to ensure only the latest state is processed.

## 🟡 Medium Severity

### 1. Inefficient Client-Side Filtering for Servants
- **File:** `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`
- **Issue:** Searching students as a servant fetches the *entire class* and filters by name in memory.
- **Risk:** Increased memory usage and network overhead as class sizes grow.
- **Fix:** Implement a server-side query that combines `classId` and name prefix matching.

### 2. Redundant Field Query for ID Lookups
- **File:** `lib/features/student/data/repos/student_data_repository.dart`
- **Issue:** `getStudentByUid` performs a `where('uid', isEqualTo: ...)` query.
- **Risk:** Since `uid` is established as the `docID` in `StudentProfileBloc`, this is 2-3x slower and more expensive than a direct document fetch.
- **Fix:** Refactor `getStudentByUid` to call `getStudentById(uid)`.

### 3. Side-Effects in Read-Only BLoC Event
- **File:** `lib/features/student/presentation/bloc/student_profile/student_profile_bloc.dart`
- **Issue:** `StudentProfileLoadRequested` triggers a Firestore write (upsert) if the profile is missing.
- **Risk:** Violates separation of concerns. Makes debugging harder as "loading" data can change the state of the database.
- **Fix:** Move profile creation to the registration flow or a dedicated `StudentProfileCreateRequested` event.

### 4. Inefficient Fallback Logic in `getStudentsByClass`
- **File:** `lib/features/student/data/repos/student_data_repository.dart`
- **Issue:** Uses a `whereIn` fallback with chunking.
- **Risk:** Indicates inconsistent data schema where `classId` is not reliably populated.
- **Fix:** Ensure `classId` is always set during student creation/migration and remove the fallback.

## 🟢 Low Severity

### 1. Leftover Debug Logging
- **Status:** ✅ Fixed
- **Fix:** Removed debug prints with PII from `AuthBloc`.

### 2. Redundant Data Storage
- **File:** `lib/core/utils/data_seeder.dart`
- **Issue:** `assignMeAsStudentAndCreateProfile` writes identical data to both `Students` and `Users` collections.
- **Risk:** Data synchronization issues.
- **Fix:** Use a single source of truth or implement Firestore Triggers to keep them in sync.

---
*Last updated: Thursday, February 5, 2026*
