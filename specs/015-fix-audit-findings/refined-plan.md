# Refined Production Audit Remediation Plan (v1.1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remediate production audit findings for scalability, security, and data integrity (excluding offline sync).

**Architecture:** 
1. **Read Models:** Introduce additive read-model collections for attendance history and team summaries to solve O(N) query explosion.
2. **Atomic Writes:** Transition from high-latency Transactions to `WriteBatch` where possible for better network resilience.
3. **Auditability:** Close audit gaps in Cloud Functions and session lifecycle events.
4. **Access Safeguards:** Enforce custom claim refreshes and password-change gating for restored accounts.

**Tech Stack:** Flutter, Firebase Auth, Firestore, Cloud Functions (Node/TS), flutter_bloc, get_it.

---

## Phase 1: Shared Infrastructure & Logging

**Purpose:** Prepare data models and logging infrastructure.

### Task 1: Add Read-Model Collection Constants
**Files:**
- Modify: `lib/core/constants/firestore_collections.dart`
- [ ] Add `attendanceHistory` and `attendanceStats` constants.

### Task 2: Implement Admin Audit Logging in Cloud Functions
**Files:**
- Modify: `functions/src/index.ts`
- [ ] Add a helper to write audit logs to the `audit_logs` collection.
- [ ] Update `archiveManagedUser` and `restoreManagedUser` to write audit entries.

---

## Phase 2: Core Attendance Hardening

**Purpose:** Solve transaction bottlenecks and scalability issues.

### Task 3: Migrate Marking to WriteBatch
**Files:**
- Modify: `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] Replace `runTransaction` in `_writeMark` with a `WriteBatch` that includes the audit log.
- [ ] Ensure idempotency by using `studentId` as the document ID.

### Task 4: Implement Attendance Read-Models (History & Stats)
**Files:**
- Modify: `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] Update mark write logic to also update the student's `attendanceHistory` read-model.
- [ ] Implement stats aggregation (increment/decrement) in the repository or via Cloud Function triggers.

---

## Phase 3: Security & Session Lifecycle

**Purpose:** Fix session duplication and access refresh.

### Task 5: Enforce Session Uniqueness inside Batch
**Files:**
- Modify: `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] Use a deterministic document ID for sessions based on `dateKey` + `teamId` + `normalizedTitle` to prevent duplicates.

### Task 6: Role Refresh & Password Gating
**Files:**
- Modify: `lib/Features/auth/presentation/bloc/auth_bloc.dart`
- [ ] Force a token refresh when a permission error is detected.
- [ ] Implement navigation gating for `restorePendingPasswordReset` users.

---

## Phase 4: Verification

**Purpose:** Ensure P1 issues are resolved.

### Task 7: Scalability Test
- [ ] Verify team summary load time with simulated high-volume data.
### Task 8: Duplication Test
- [ ] Verify session creation uniqueness under simultaneous requests.
