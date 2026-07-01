# BLoC Review

## Scope: All Feature BLoCs

---

### 1. Attendance Taking BLoC (`attendance_taking_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| MutationStatus dedup | Uses `MutationStatus` enum to prevent duplicate mark submissions | ✅ |
| Pending merge | Merges pending local marks with synced data correctly | ✅ |
| Loading states | Proper loading state per student | ✅ |
| **Missing offline state** | No explicit offline-specific state — relies on global indicator | 🟡 Minor |

### 2. Attendance Session Admin BLoC (`attendance_session_admin_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Session management | Handles create/read/update/delete of sessions | ✅ |
| **Missing offline state** | No explicit offline-aware state for session operations | 🟡 Minor |
| Error handling | Basic error state | ✅ |

### 3. Student Data BLoC (`student_data_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Data loading | Loads student list from repository | ✅ |
| **Missing offline state** | No offline-specific state emission | 🟡 Minor |
| Empty state | Implicit empty list — not explicit | 🟡 Minor |

### 4. Student Profile BLoC (`student_profile_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Profile management | Handles student profile CRUD | ✅ |
| Form state | Proper form validation state | ✅ |
| Error handling | Adequate | ✅ |

### 5. Servant Data BLoC (`servant_data_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Data loading | Loads servant list from repository | ✅ |
| **Missing offline state** | No offline-specific state emission | 🟡 Minor |
| Error handling | Basic | ✅ |

### 6. Team BLoC (`team_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No offline support** | All reads hit Firestore directly — no local Hive caching. Teams unavailable offline. | 🟠 Important |
| Error handling | Returns error state when Firestore unavailable | ✅ |
| State coverage | Loading, loaded, error — but no cached/offline state | 🟠 Important |

### 7. Team Members BLoC (`team_members_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No offline support** | Same issue as Team BLoC — direct Firestore reads only | 🟠 Important |
| Error handling | Returns error when offline | ✅ |

### 8. Results BLoC (`results_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Data loading | Loads results from repository | ✅ |
| **Missing offline state** | No offline-specific state | 🟡 Minor |
| Error handling | Basic | ✅ |

### 9. Admin Dashboard BLoC (`admin_dashboard_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No offline support** | Fetches ALL data from Firestore on each load. No local caching. Dashboard is completely unavailable offline. | 🟠 Important |
| Firestore cost | No caching means every dashboard load = N Firestore reads | 🟠 Important |
| State coverage | Loading, loaded, error — no cached/offline fallback | 🟠 Important |

---

## Summary

| BLoC | Offline State | Empty State | Error State | Caching |
|------|---------------|-------------|-------------|---------|
| AttendanceTaking | 🟡 Implicit | ✅ | ✅ | ✅ Repo |
| AttendanceSessionAdmin | 🟡 Missing | ✅ | ✅ | ✅ Repo |
| StudentData | 🟡 Missing | 🟡 Implicit | ✅ | ✅ Repo |
| StudentProfile | 🟡 Missing | ✅ | ✅ | ✅ Repo |
| ServantData | 🟡 Missing | 🟡 Implicit | ✅ | ✅ Repo |
| Team | 🟠 Missing | 🟡 Implicit | ✅ | 🔴 None |
| TeamMembers | 🟠 Missing | 🟡 Implicit | ✅ | 🔴 None |
| Results | 🟡 Missing | 🟡 Implicit | ✅ | ✅ Repo |
| AdminDashboard | 🟠 Missing | ✅ | ✅ | 🔴 None |

---

## Recommendations

1. **🟠 Important**: Add local Hive caching to Team BLoC, TeamMembers BLoC, and AdminDashboard BLoC.
2. **🟡 Minor**: Add explicit offline states (`AttendanceOffline`, `DataCached`) to all BLoCs.
3. **🟡 Minor**: Add explicit empty states instead of relying on empty list rendering.
