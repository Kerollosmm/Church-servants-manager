# 🏛️ PRODUCTION-GRADE TECHNICAL AUDIT
## Church Servants Management System (CSMS)
### CTO-Level Review — March 2026

---

## A. EXECUTIVE VERDICT

| Dimension | Score |
|---|---|
| **Overall Architecture** | 6.5 / 10 |
| **Business Logic** | 6.0 / 10 |
| **Offline Sync** | 3.5 / 10 |
| **Security** | 6.5 / 10 |
| **Performance** | 5.0 / 10 |
| **Production Readiness** | 4.0 / 10 |

**Honest Verdict:** The codebase reflects a competent clean-architecture skeleton with well-structured domain/data/presentation separation, strong use of freezed models, and a thoughtful Firestore write model for attendance marks. However, the app is **not production-ready**. Entire feature UI surfaces are blanked out for redesign (`// Blanked for redesign` in all attendance screens/widgets), meaning no end-to-end flow is currently exercisable. The offline-first claim is dangerous fiction: the "sync engine" is Firestore SDK offline persistence alone — there is no pending queue, no retry mechanism, no sync status, no conflict resolution strategy, and no recovery path when writes fail while offline. Attendance marks written offline could silently fail with zero user feedback. The Firestore security rules contain multiple critical privilege-escalation vectors and client-trust assumptions. The servant `deleteServant()` hardcodes `archivedByUserId: 'system'`, destroying audit integrity. The `callerUser()` helper in rules triggers a document read on every rule evaluation, driving cost and latency to dangerous levels at any real-world scale. Without the UI layer present, no attendance session can actually be created, taken, or reviewed by users today. The architecture shows clear signs of thoughtful design that needs 4–6 more weeks of focused hardening before production deployment.

---

## B. CRITICAL ISSUES (P0 / P1)

---

### B1. ENTIRE ATTENDANCE UI IS DEAD CODE
**Severity: P0**

**Why it's dangerous:** Every screen and widget in `lib/Features/attendance/presentation/screens/` and `lib/Features/attendance/presentation/widgets/` is blanked — empty stubs with `// Blanked for redesign`. This means the core business function of the app — taking attendance — has **zero functional UI**. Users cannot create a session, view a roster, or mark a student.

**Where it appears:**
- `attendance_history_screen.dart`, `attendance_session_create_screen.dart`, `attendance_taking_screen.dart`, `student_attendance_screen.dart`
- All 12 widget files in `presentation/widgets/`

**Root cause:** A UI refactor was started (spec `012-ui-clean-refactor`) and all original screens were blanked without replacements being committed.

**Real-world impact:** The app cannot fulfill its primary purpose. Any deployment in current state is non-functional for attendance operations.

**Recommended fix:** Restore working screens before any further refactoring. Never blank existing functionality without an in-place replacement.

---

### B2. NO OFFLINE WRITE QUEUE — SILENT DATA LOSS
**Severity: P0**

**Why it's dangerous:** The app claims to be "offline-first" but relies entirely on Firestore SDK's built-in offline persistence. There is no custom pending-write queue, no sync status per record, no retry logic on app restart, no user notification of pending vs confirmed writes, and no recovery path when a write fails. When a servant marks attendance offline, the write sits in Firestore's internal pending queue. If the app is force-closed, the device restarts, or memory is cleared, **that pending write may be permanently lost** with the user seeing no indication.

**Where it appears:** `attendance_repository.dart` `_writeMark()`, `markAllPresentForRemainingStudents()` — all writes go directly to Firestore with no local queue. `servant_data_repository.dart` and `student_data_repository.dart` follow the same pattern.

**Root cause:** `persistenceEnabled: true` with `cacheSizeBytes: 100MB` in `injection.dart` was treated as equivalent to a proper offline-first sync engine. It is not.

**Real-world impact:** A servant marks 40 students during church service, the phone's screen times out and the OS kills the app due to memory pressure. Zero of those marks are persisted. The servant has no awareness. The session shows all students absent in reports.

**Recommended fix:** Implement a `PendingWriteQueue` backed by Hive (already a dependency). Each attendance mark write should be: (1) written to Hive with status `pending`, (2) written to Firestore, (3) on success, updated to `synced`. On app start, all `pending` records should be replayed. Expose sync status per roster item in the UI.

---

### B3. `deleteServant()` HARDCODES `archivedByUserId: 'system'`
**Severity: P1**

**Why it's dangerous:** This destroys audit integrity. The audit trail requirement — who deleted whom and when — is a core compliance requirement for any management system. When a servant is archived, the record shows `archivedByUserId: 'system'` with no traceability.

**Where it appears:** `lib/Features/servant/data/repo/servant_data_repository.dart` line 336:
```dart
'archivedByUserId': 'system',
```

**Root cause:** The `deleteServant(String docId)` interface does not accept a `performedByUid` parameter, unlike `deleteStudent()` which was correctly fixed (`// FIX [004-C2]`). The fix was applied to students but not servants. `restoreServant()` also lacks `restoredByUserId`.

**Real-world impact:** Compliance audit finds no record of who archived a servant. Admin disputes cannot be resolved. Accountability is absent.

**Recommended fix:** Mirror the student pattern — add `{required String performedByUid}` parameter to `deleteServant()` and `restoreServant()` in `IServantRepository` and propagate through all use cases.

---

### B4. FIRESTORE RULES: `callerUser()` IS A CHARGED READ ON EVERY RULE CHECK
**Severity: P1**

**Why it's dangerous:** The helper `callerUser()` calls `get(/databases/.../Users/$(callerUid()))` and is invoked inside `isAdmin()`, `isServant()`, `servantCanReadStudent()`, `linkedStudentCanReadSession()`, and more. Every single Firestore operation triggers a hidden document read on the Users collection. This is a **billed Firestore read for every rule evaluation**.

**Where it appears:** `firestore.rules` lines 13–30, called from every rule helper function.

**Root cause:** Rules rely on dynamic document lookup instead of custom claims or token-embedded role data.

**Real-world impact:** For a team of 40 students during a session: loading the roster = 40 rule evaluations × ~2 helper calls = 80+ hidden `Users` reads. At scale with multiple teams, this multiplies costs and slows rule evaluation latency significantly.

**Recommended fix:** Embed `role` and `isArchived` into Firebase Auth custom claims (the Cloud Function `createPrivilegedUser` already calls `adminAuth.setCustomUserClaims` — expand this to include `isArchived`). Then use `request.auth.token.role` and `request.auth.token.isArchived` in rules instead of `callerUser()` reads. Remove the `get()` call entirely from hot-path rules.

---

### B5. RACE CONDITION: CONCURRENT MULTI-DEVICE MARK OVERWRITES IN `markAllPresentForRemainingStudents()`
**Severity: P1**

**Why it's dangerous:** `markAllPresentForRemainingStudents()` reads existing marks, computes `remainingIds`, then batch-writes them. Between the read and the batch write, another device could mark some students. Servant A's batch commit will **overwrite** servant B's marks with `present` even if servant B marked them `late`. The batch uses `SetOptions(merge: true)` so it will not fail — it will silently overwrite.

**Where it appears:** `attendance_repository.dart` lines 690–716.

**Root cause:** The read-compute-write pattern is not atomic. A Firestore transaction was not used, and individual mark writes do not check existing status before overwriting.

**Real-world impact:** During a real service with 2 servants marking simultaneously, one servant hits "mark all present," obliterating legitimate "late" marks set by the other servant in the last few seconds.

**Recommended fix:** Use Firestore transactions for the "mark all remaining" operation, or add conditional write logic that only creates marks where no document currently exists. The batch should skip students who already have a mark document.

---

### B6. SECURITY: DUAL STUDENT SELF-READ FIELDS CREATE INCONSISTENCY AND AUDIT GAP
**Severity: P1**

**Why it's dangerous:** The Firestore rule for `Students/{studentId}` allows read if `resource.data.linkedUserId == callerUid()` OR `resource.data.uid == callerUid()`. Both `uid` and `linkedUserId` are written at different times by different code paths, creating a dual-field inconsistency. A student could potentially access a student document if a stale `uid` field matches their UID.

**Where it appears:** `firestore.rules` lines 203–208; `student_data_repository.dart` `_studentWriteData()` writes both fields; `student_linked_user_sync_service.dart` writes `linkedUserId`.

**Root cause:** Historical field naming confusion between `uid` (original field) and `linkedUserId` (canonical link field). Both exist in the rules as fallbacks.

**Real-world impact:** Rule reasoning is unauditable. A data migration bug could expose one student's record to another.

**Recommended fix:** Standardize on `linkedUserId` as the single canonical link field. Remove `resource.data.uid == callerUid()` from rules. Run a migration to populate `linkedUserId` for all existing student documents.

---

### B7. `authStateChanges` FORCE-REFRESHES FIRESTORE ON EVERY AUTH STATE EMISSION
**Severity: P1**

**Why it's dangerous:** `FirebaseAuthProvider.authStateChanges` calls `asyncMap` with `getUserData(user.uid, forceRefresh: true)` on every Firebase Auth state emission. Firebase Auth can emit multiple rapid state changes (token refresh, app resume, network reconnect). Each emission triggers a Firestore document read, bypassing the in-memory cache.

**Where it appears:** `firebase_auth_provider.dart` lines 32–39.

**Root cause:** `forceRefresh: true` is unconditional, bypassing the in-memory `_userCache` on every auth state event.

**Real-world impact:** On app resume from background, Firebase Auth emits an auth state change, triggering an immediate Firestore read. With poor connectivity this blocks the UI. With many users repeatedly backgrounding the app, this creates a billing spike.

**Recommended fix:** Use `forceRefresh: false` by default in `authStateChanges`. Only force-refresh on explicit user action (login, manual refresh) or after a configurable debounce period (e.g., 60 seconds since last refresh).

---

### B8. NO TRANSACTION PROTECTION FOR SESSION TIME-OVERLAP CONFLICT CHECK
**Severity: P1**

**Why it's dangerous:** In `createSession()`, the overlap/duplicate check queries open sessions outside the transaction, then runs a transaction that only checks for exact ID collision. Two concurrent admins could both pass the overlap check and both succeed in creating conflicting sessions.

**Where it appears:** `attendance_repository.dart` lines 497–524 — the `existingSnapshot` query runs before `_firestore.runTransaction(...)`.

**Root cause:** The pre-transaction query runs outside the atomic boundary. The transaction only prevents exact-ID duplicate, not logical time-overlap duplicate.

**Real-world impact:** Two admins on different devices simultaneously create overlapping sessions. Both pass the conflict check. Both sessions exist. Servants are confused about which session to use. Attendance data is split across two sessions.

**Recommended fix:** Move the overlap check inside the transaction using a `get()` call within `runTransaction`. Or use a sentinel lock document (`Classes/{teamId}/locks/active-session`) to serialize session creation per team.

---
