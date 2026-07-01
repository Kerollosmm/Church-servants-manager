# CSMS Critical Fix Plan

## Audit Origin

This plan addresses the **No-Go** verdict from the comprehensive code review of the CSMS Flutter/Firebase application. The review identified **6 Critical Issues**, **5 Important Issues**, and **10 Suggested Improvements** across security, data-integrity, and architecture.

## Target Branch

`fix/code-review-critical-issues`

## Priority Matrix

| Priority | Issue # | File | Title | Severity |
|----------|---------|------|-------|----------|
| P0 | 1 | `firestore.rules` | Insecure Servant Read Scoping | 🔴 Critical |
| P0 | 2 | `attendance_command_service.dart` | Duplicate Offline Session Creation | 🔴 Critical |
| P0 | 3 | `student_data_bloc.dart` / `firestore.rules` | Server-Side Role Validation Missing | 🔴 Critical |
| P0 | 4 | `sync_service.dart` | enqueue() Silently Fails If No User | 🔴 Critical |
| P0 | 5 | `student_data_repository.dart` | Student Create Race Condition | 🔴 Critical |
| P1 | 6 | `sync_service.dart` | Unstable Sort Key in Sync Queue | 🟠 Important |
| P1 | 7 | `firestore.rules` | Mark Write Team Validation Missing | 🟠 Important |
| P1 | 8 | `attendance_command_service.dart` | batchWriteMarks Misses presentCount | 🟠 Important |
| P1 | 9 | `student_data_repository.dart` | Dead syncOfflineUpdate Code | 🟠 Important |
| P2 | 10 | `sync_service_test.dart` | Missing Workmanager Failure Test | 🟡 Suggest |

---

## Phase 1: Firestore Security Rules (Fix #1, #3, #7)

### 1.1 Fix Servant Read Scoping

**File:** `firestore.rules`  
**Line:** 228-233  
**Problem:** `isServantOrAdmin()` in `PointsLedger` read rule grants read to ALL servants without sector/team scoping.

**Current (vulnerable):**
```javascript
allow read: if isSignedIn() && (
  studentId == uid() ||
  isAdmin() ||
  isServantOrAdmin()  // ❌ ALL servants can read ALL points
);
```

**Required (scoped):**
```javascript
allow read: if isSignedIn() && (
  studentId == uid() ||
  isAdmin() ||
  (isServantOrAdmin() && callerManagesStudent(resource.data))  // ✅ scoped to assigned sector/team
);
```

### 1.2 Add Server-Side Role Validation

**File:** `firestore.rules`  
**Line:** 200-214  
**Problem:** `isPrivilegedStudentField()` only checks mutation of `role` field, but doesn't validate the role value itself (e.g., preventing a student from setting their own role to `admin`).

**Required:**
```javascript
function isValidRoleField() {
  let newRole = request.resource.data.get('role', '');
  // Only admin can set role to 'admin' or 'servant'
  return newRole == '' || 
         newRole == 'student' || 
         (isAdmin() && (newRole == 'admin' || newRole == 'servant'));
}
```

### 1.3 Validate Mark Writes Against Team Assignment

**File:** `firestore.rules`  
**Line:** 348-361  
**Problem:** `records/{markId}` create/update validate `teamId` from request data, but don't verify the servant actually manages that team.

**Required:**
```javascript
allow create: if isSignedIn() && (
  isAdmin() ||
  (request.resource.data.get('teamId', '') != '' && 
   callerManagesTeam(request.resource.data.teamId))
);
```

---

## Phase 2: Offline Sync Integrity (Fix #2, #4, #6)

### 2.1 Prevent Duplicate Offline Session Creation

**File:** `attendance_command_service.dart`  
**Line:** 139-149  
**Problem:** Offline path enqueues sync entry but doesn't prevent duplicate local session creation if called multiple times with same parameters.

**Required Change (approximate):**
```dart
// Before enqueuing, check local cache for existing session with same team + dateKey
if (isOffline) {
  final existing = await _localDatasource.getSessionByTeamAndDateKey(
    normalizedTeamId, 
    candidate.dateKey
  );
  if (existing != null) {
    throw const AttendanceSessionConflictFailure();
  }
  final syncEntry = SyncEntry(...);
  await getIt<SyncService>().enqueue(syncEntry);
  await _localDatasource.cacheSession(candidate);
  return candidate;
}
```

### 2.2 Fix enqueue() Silent Failure

**File:** `sync_service.dart`  
**Line:** 179-186  
**Problem:** Returns silently if no user authenticated, losing data without caller notification.

**Required Change:**
```dart
Future<bool> enqueue(SyncEntry entry) async {
  if (_activeUserId == null) {
    developer.log('Rejected enqueue: no authenticated user');
    return false; // or throw NoActiveUserException()
  }
  // ... existing logic
  return true;
}
```

### 2.3 Add Stable Secondary Sort Key

**File:** `sync_service.dart`  
**Line:** 266-268  
**Problem:** Sorting by `createdAt` alone is unstable if multiple entries created in same millisecond.

**Required Change:**
```dart
final entries = targetBox.values.toList()
  ..sort((a, b) {
    final timeCompare = a.createdAt.compareTo(b.createdAt);
    if (timeCompare != 0) return timeCompare;
    return a.id.compareTo(b.id); // stable tie-breaker
  });
```

---

## Phase 3: Student Data Race Conditions (Fix #5)

### 3.1 Wrap Student Create in Transaction

**File:** `student_data_repository.dart`  
**Line:** 266-297  
**Problem:** UUID generation followed by separate Firestore write creates potential for duplicate IDs under concurrent writes.

**Required Change:**
```dart
Future<String> createStudent(Student student) async {
  try {
    final docId = student.docID.isNotEmpty
        ? student.docID
        : const Uuid().v4();
    
    final finalStudent = StudentModel.fromDomain(student).copyWith(
      docID: docId,
      syncStatus: SyncStatus.pending,
      clientUpdatedAt: DateTime.now(),
    );

    await _localDatasource.saveStudent(finalStudent);

    // If online, immediately sync to Firestore atomically
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await _firestore.runTransaction((transaction) async {
        final docRef = _studentsCollection.doc(docId);
        final existing = await transaction.get(docRef);
        if (existing.exists) {
          throw StudentDuplicateIdFailure('Student with ID $docId already exists');
        }
        transaction.set(docRef, finalStudent.toMap());
      });
    }

    final syncEntry = SyncEntry(
      id: 'upsert_student_$docId',
      actionType: 'UPSERT_STUDENT',
      payload: {'student': finalStudent.toMap()},
      createdAt: DateTime.now(),
    );

    await _syncServiceGetter().enqueue(syncEntry);
    developer.log('Enqueued CREATE student: $docId', name: 'StudentDataRepository');

    return docId;
  } catch (e) {
    developer.log('Create student failed', error: e, name: 'StudentDataRepository');
    rethrow;
  }
}
```

---

## Phase 4: Denormalized Data Consistency (Fix #8)

### 4.1 Update presentCount in batchWriteMarks

**File:** `attendance_command_service.dart`  
**Line:** 832-ި873  
**Problem:** Batch write marks session document but never updates `presentCount`, causing aggregate inconsistency.

**Required Change:**
```dart
Future<void> batchWriteMarks({
  required String teamId,
  required String sessionId,
  required Map<String, AttendanceMarkStatus> marks,
  required AuthUser markedBy,
  bool cachedPermission = false,
}) async {
  try {
    final sessionRef = _sessionDoc(teamId, sessionId);
    final sessionDoc = await _cachedGet(sessionRef);
    // ... existing validation ...

    final entries = marks.entries.toList(growable: false);
    int newPresentCount = 0;
    
    for (final chunk in entries.chunk(400)) {
      final batch = _firestore.batch();
      for (final entry in chunk) {
        final studentId = entry.key;
        final status = entry.value;
        final markRef = _markDoc(teamId, sessionId, studentId);
        final studentName =
            session.studentNameSnapshots[studentId] ?? 'مخدوم';
        batch.set(markRef, {
          'studentId': studentId,
          'studentNameSnapshot': studentName,
          'status': status.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Track present count
        if (status == AttendanceMarkStatus.present) {
          newPresentCount++;
        }
      }
      await batch.commit();
    }

    // Atomically update session presentCount
    if (newPresentCount > 0) {
      await sessionRef.update({
        'presentCount': FieldValue.increment(newPresentCount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (error) {
    if (error is AttendanceFailure) rethrow;
    throw mapExceptionToAttendanceFailure(error);
  }
}
```

---

## Phase 5: Dead Code & Testing (Fix #9, #10)

### 5.1 Connect syncOfflineUpdate or Remove

**File:** `student_data_repository.dart`  
**Line:** 462-474  
**Problem:** `syncOfflineUpdate` is defined but never invoked by the sync handler lookup table.

**Decision Needed:** Either:
- **Option A:** Register the handler in `SyncService` constructor mapping:
  ```dart
  'UPDATE_STUDENT': StudentSyncHandler(studentRepo), // calls syncOfflineUpdate
  ```
- **Option B:** Remove the dead code entirely if `syncOfflineUpsert` is the only handler needed.

### 5.2 Add Workmanager Failure Path Test

**File:** `test/core/services/sync_service_test.dart`  
**Line:** N/A (new test)  
**Problem:** No test verifies behavior when periodic sync task registration fails.

**Required Test:**
```dart
test('gracefully handles Workmanager registration failure', () async {
  final failingConnectivity = MockConnectivity();
  when(() => failingConnectivity.onConnectivityChanged)
      .thenAnswer((_) => const Stream.empty());
  when(() => failingConnectivity.checkConnectivity())
      .thenAnswer((_) async => [ConnectivityResult.none]);

  final service = SyncService(
    deadLetterQueue: mockDlq,
    connectivity: failingConnectivity,
    handlers: {},
  );

  // Mock Workmanager to throw on registerPeriodicTask
  // (Requires MockWorkmanager or similar)

  await service.init();
  await service.setAuthenticatedUser('test_user');

  // Assert: service should still be functional despite Workmanager failure
  expect(service.pendingCount, 0);
  expect(service.isProcessing, false);
});
```

---

## Dependencies & Blockers

| Dependency | Status | Action |
|-----------|--------|--------|
| Firestore rules test framework | ⚠️ Partial | Run `security_rules_test_firestore/tests/firestore.test.js` after changes |
| `AttendanceSessionLocalDatasource` | ⚠️ Unknown | Verify `getSessionByTeamAndDateKey` exists; if not, add it |
| Flutter/Dart SDK | ✅ OK | No changes needed |

## Rollback Plan

If any fix introduces regression:
1. Revert the specific file change using `git checkout <file>`
2. Re-run `flutter test` to verify baseline state
3. Retry fix with narrower scope

## Definition of Done

- [ ] All 6 Critical issues have corresponding code changes
- [ ] All 5 Important issues have corresponding code changes
- [ ] `firestore.test.js` passes after rules changes
- [ ] `sync_service_test.dart` passes after sync changes
- [ ] `flutter test` passes at repo root
- [ ] UI manual test: verify servant cannot read out-of-scope student data
- [ ] UI manual test: verify offline session creation deduplication
