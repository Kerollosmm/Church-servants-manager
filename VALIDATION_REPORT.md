# CSMS Security Remediation Plan - Validation Report

**Date:** 2026-06-28  
**Prepared by:** AI Agent  
**Scope:** Tasks & Specification Validation  

---

## 1. Constitution Validation

| Constitution Principle | Validation Status | Details |
|---|---|---|
| **1. Zero Cloud Functions** | ✅ PASS | All 76 tasks in `tasks.md` are client-side (Flutter/Dart) only. No Cloud Functions, scheduled tasks, or backend triggers are mentioned. |
| **2. Offline-First & Data Idempotency** | ✅ PASS | Tasks T009-T017 explicitly implement the Transaction Log pattern for atomic writes. Tasks T027-T035 enforce `syncStatus` in Firestore for LWW resolution. All user stories include offline considerations. |
| **3. Absolute Quota Optimization** | ✅ PASS | Task T062 defines a composite index for `searchStudents`. Task T064 verifies query optimization. No tasks suggest collection scans or `.watch()`. `whereIn` max 10 items is enforced in US1. |
| **4. Document-Based RBAC** | ✅ PASS | Tasks T051-T055 reconcile `CanMutateStudentUseCase` with `firestore.rules`. The `roleUserRoute` and all BLoC tasks respect the document-based role pattern. No Custom Claims are mentioned. |
| **5. Clean Architecture** | ✅ PASS | All tasks respect the `Domain -> Data -> Presentation` structure. Business logic is in UseCases/BLoCs (e.g., US5), data in Repositories (e.g., US2), and UI in Widgets (e.g., US6). No logic leaks to the presentation layer. |

---

## 2. Task Completeness & Correctness

| Requirement | Status | Evidence |
|---|---|---|
| **Checkbox Format** | ✅ PASS | All 76 tasks follow the `- [ ] T### [P] [US#] Description` format. |
| **User Story Organization** | ✅ PASS | Tasks are grouped by Phase (Setup, Foundational, US1-US6, Infrastructure, Type Safety, Verification). Each US has its own Phase. |
| **Parallel Execution Opportunities** | ✅ PASS | Identified in Phase 11 (5 parallel groups). All `[P]` tasks are genuinely parallelizable (no shared file dependencies within a group). |
| **Independent Test Criteria** | ✅ PASS | Each US has explicit acceptance criteria. Tasks T024, T026, T034, T035, T042, T050, etc., are dedicated test tasks. |
| **MVP Scope Defined** | ✅ PASS | Phase 1 + Phase 2 + Phase 3 + Phase 4 (Tasks T001-T035) are explicitly suggested as MVP. This covers the 4 CRITICAL issues. |
| **File Paths Included** | ✅ PASS | Every task references specific files, e.g., `lib/features/student/data/repos/student_data_repository.dart`. |

---

## 3. Specification Accuracy

| Issue from Code Review | Status in `clarifying_spec.md` | Accuracy |
|---|---|---|
| **Data Leakage (SEC-001)** | Documented as Issue 1 | ✅ Accurate: Points to exact file and line, describes the exploit, and explains the fix principle. |
| **Duplicate Writes (SEC-002)** | Documented as Issue 2 | ✅ Accurate: Explains the non-atomic write problem and the Transaction Log solution. |
| **Connectivity Trust (SEC-003)** | Documented as Issue 3 | ✅ Accurate: Explains why client-side connectivity is untrustworthy. |
| **Missing syncStatus (SEC-004)** | Documented as Issue 4 | ✅ Accurate: Explains why `syncStatus` is critical for LWW and conflict resolution. |
| **BLoC State Instability (SEC-005)** | Documented as Issue 5 | ✅ Accurate: Describes the race condition and the `loading` state fix. |
| **RBAC Divergence (SEC-006)** | Documented as Issue 6 | ✅ Accurate: Explains the `assignedTeamId` vs `assignedTeamIds` mismatch. |
| **Missing Composite Index (SEC-007)** | Documented as Issue 7 | ✅ Accurate: Explains the `classId` + `name` composite index requirement. |
| **DLQ Integration (SEC-)` | Documented as Issue 8 | ✅ Accurate: Explains why the DLQ is currently decoration-only. |
| **BLoC Lifecycle (SEC-009)** | Documented as Issue 9 | ✅ Accurate: Explains the `StatelessWidget` vs `StatefulWidget` problem. |
| **Type Safety (SEC-010)** | Documented as Issue 10 | ✅ Accurate: Describes the `Map<String, Object?>` problem. |

---

## 4. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Task T021 (Constitution Check for >10 teams)** | Medium | High | Fallback to `groupId` query is already planned. Ensure the fallback doesn't violate Quota Optimization (it should be a single-document lookup). |
| **Task T027-T035 (Atomic Writes)** | Low | High | Transaction Log pattern is well-established. Ensure Hive write and Firestore write are in separate `try-catch` blocks for granular error handling. |
| **Task T036-T042 (Sync Engine Robustness)** | Low | Medium | Removing connectivity checks is safe as long as handlers catch network errors correctly. Ensure `FirebaseException` handling is comprehensive. |
| **Task T062-T064 (Composite Index)** | Low | Medium | Index deployment is a one-time Firebase operation. Ensure it's tested in a staging environment first. |

---

## 5. Recommendations for Agent Execution

1. **Start with Phase 1 (Setup):** Always create the backup branch first. This is a non-negotiable safety step.
2. **Parallelize Phase 2 and Phase 3:** While the Transaction Log is being built (T009-T017), another agent can work on `searchStudents` authorization (T018-T026) because they touch different files initially.
3. **Test Early and Often:** Do not wait until Phase 11 to write tests. Every task should be testable. Run tests after every Phase completion.
4. **Monitor Firestore Quotas:** During development, keep an eye on the Firebase Console > Firestore > Usage tab. The `searchStudents` fix (T062-T064) should significantly reduce read counts.
5. **Update `clarifying_spec.md`:** If new issues are discovered during implementation, update the specification immediately. Do not let the documentation drift from the code.

---

## 6. Final Verdict

**The `tasks.md` plan and `clarifying_spec.md` are validated, constitution-compliant, and ready for execution.**

All 10 critical issues are addressed. The plan is phased logically, starting with the most critical security fixes (data leakage, atomic writes) and moving to robustness (DLQ, BLoC stability). The specification provides enough detail for any AI agent or developer to understand the "why" and the "how" without additional context.

**Recommended Next Step:** An AI agent should pick up Task T001 (read and understand the plan) and proceed through Phase 1 and Phase 2.
