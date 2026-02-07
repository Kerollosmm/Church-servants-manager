# Elite Senior Audit Report - Church Servants Manager (CSMS)

**Date:** 2026-02-06
**Auditor:** Elite Senior AI Agent
**Status:** Needs Improvement (Significant Architectural and Sync Gaps)

---

## 1. Security Audit
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **User Role Spoofing** | **Critical** | Users can choose their own role (`servant`) in `RegisterScreen.dart`, and the Firestore rules allow setting the `role` field during creation if `auth.uid == userId`. An attacker can spoof `admin` role by tampering with the request. |
| **Insecure Firestore Rules (Users)** | **Major** | `allow read: if isAuthenticated();` in `firestore.rules` allows any logged-in user to read the full profile of every other user, including roles and potentially sensitive info. |
| **Compromised RBAC** | **Major** | Since roles can be spoofed at registration, the `isServantOrAdmin()` check in Firestore rules for `students`, `classes`, and `attendance` is effectively bypassed. |
| **Silent Login Failures** | Major | `FirebaseAuthProvider` catches exceptions and throws `GenericAuthException` without specific error codes in many places, losing the underlying cause for the UI. |
| **Missing Input Validation** | Medium | Registration and Student forms rely on basic UI-level validation. No centralized business-rule validation exists in the domain layer. |

---

## 2. Performance Audit
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **N+1 Potential in Auth** | Medium | `authStateChanges` uses `asyncMap` to fetch user data for every auth state change. This could lead to redundant network calls if not cached. |
| **Lack of Pagination UI** | Major | `StudentDataRepository` supports pagination, but `StudentDataBloc` and the UI (`StudentManagementScreen`) load all students (or a fixed limit) at once. No infinite scroll implemented. |
| **Search Result Cap** | Medium | Search results are hardcapped at 20 in `StudentDataRepository.searchStudents`, with no way to load more. |
| **Missing Image Caching** | Medium | `StudentModel` uses `imageUrl`, but the project doesn't use `cached_network_image`, causing repeated downloads of profile pictures. |
| **Expensive Firestore IN Queries** | Low | `getStudentsByClass` uses chunks of 10 for `whereIn`. While implemented correctly, this is a fallback that should ideally be replaced by the `classId` index in all records. |

---

## 3. Logic & Synchronization Audit
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **Hive Initialization Missing** | **Critical** | `pubspec.yaml` includes Hive, but `main.dart` does not initialize it, and no repository uses it. **Offline support is currently non-existent.** |
| **No Versioning for Sync** | Major | `StudentModel` lacks `updatedAt` or `version` fields, making it impossible to perform meaningful "Last Write Wins" or conflict resolution during future sync implementation. |
| **Dual-Write Fragility** | Major | `StudentDataRepository` uses Firestore batches for dual-writing. While safe for Firestore, there is no logic to handle eventual consistency with a local cache. |
| **Lack of Conflict Resolution** | Major | When offline support is added, the current architecture lacks a "last-write-wins" or "versioning" strategy for syncing local Hive data with Firestore. |

---

## 4. Architectural Audit
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **Hive-Firestore Leaks** | Major | Models are currently Firestore-aware (using `TimestampConverter`) but not Hive-aware (missing `@HiveType` annotations). |
| **Redundant Routing** | Minor | `AppRouter` contains repetitive logic for arguments. A more declarative approach (e.g., `go_router`) or a factory pattern for routes would be cleaner. |
| **Dependency Injection** | Medium | `main.dart` uses manual dependency injection, but `AuthService` is hardcoded to `AuthService.firebase()` inside `AuthBloc`. This makes unit testing the Bloc difficult without mocks. |

---

## 5. Prioritized Action Items
1. **[CRITICAL]** Initialize Hive and implement a Local Data Source for Students.
2. **[MAJOR]** Implement a Sync Repository that orchestrates between Hive and Firestore.
3. **[MAJOR]** Refactor `AuthBloc` and `StudentDataBloc` to accept injected repositories for better testability.
4. **[MAJOR]** Add pagination/infinite scroll to the Student Management Screen.
5. **[MEDIUM]** Annotate models with Hive types and adapters.
6. **[MEDIUM]** Centralize error mapping and handling in the domain layer.