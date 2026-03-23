# Data Model: Pre-Deploy Security & Stability Fixes

**Branch**: `004-security-stability-fixes` | **Date**: 2026-03-22

No new entities are introduced. Existing Firestore document shapes are unchanged.
The changes below are **additive field semantics** (values were already written but with
incorrect data) and **new query constraints**.

---

## Affected Firestore Documents

### 1. `Students/{docId}` — Archive/Restore Fields

Previously hardcoded to `'system'`. After fix, contain real user UIDs.

| Field | Type | Change |
|-------|------|--------|
| `archivedByUserId` | `String` | Now set to performing admin's `uid` (was `'system'`) |
| `restoredByUserId` | `String` | Now set to performing admin's `uid` (was `'system'`) |
| `archivedAt` | `Timestamp` | Unchanged — already `FieldValue.serverTimestamp()` |
| `restoredAt` | `Timestamp` | Unchanged — already `FieldValue.serverTimestamp()` |

**No schema migration needed** — field names are unchanged. Existing documents written
with `'system'` remain valid. Only future operations will write real UIDs.

---

### 2. `Classes/{teamId}/attendance_sessions` — Query Constraint

No new fields. The existing `isClosed` (`bool`) field is now used as a Firestore
**query filter** in `watchActiveSessionForTeam`, not just a client-side check.

| Field | Type | Usage Change |
|-------|------|------|
| `isClosed` | `bool` | Now used as server-side WHERE filter in open-sessions query |
| `startsAt` | `Timestamp` | Now used as server-side WHERE filter for 6-month cap |

**Firestore Index required** (for `getStudentAttendanceStats`):
- Collection group: `attendance_sessions`
- Fields: `studentIdsSnapshot` (array-contains) + `startsAt` (ascending)
- Declare in `firestore.indexes.json`

---

## New Artifacts

### `firestore.rules` (new file at repo root)

Security rules document. Covers:
- `Users` collection: read own doc; admin can read all; admin can write
- `Students` collection: admin can create/update/delete
- `Classes` collection: admin can create/update/delete
- `Classes/{teamId}/attendance_sessions`: admin can create/update/delete
- `Classes/{teamId}/attendance_sessions/{sid}/marks`: admin or assigned servant can write

### `firestore.indexes.json` (new file at repo root)

Composite index declaration for the 6-month-capped student sessions query:
```json
{
  "indexes": [
    {
      "collectionGroup": "attendance_sessions",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "studentIdsSnapshot", "arrayConfig": "CONTAINS" },
        { "fieldPath": "startsAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Dart Layer Interface Changes

### `IStudentRepository` (interface)

```dart
// Before
Future<void> deleteStudent(String docId);
Future<void> restoreStudent(String docId);  // (was not in interface)

// After
Future<void> deleteStudent(String docId, {required String performedByUid});
Future<void> restoreStudent(String docId, {required String performedByUid});
```

### `DeleteStudentUseCase` / `RestoreStudentUseCase`

```dart
// Before
Future<void> call(StudentModel student);

// After
Future<void> call(StudentModel student, {required String performedByUid});
```

### `AttendanceRepository._studentSessionsQuery` (private)

```dart
// Added optional since parameter
Query _studentSessionsQuery({
  required String studentId,
  String? teamId,
  DateTime? since,   // NEW — filters startsAt >= since
});
```

No public interface (`IAttendanceRepository`) changes.
