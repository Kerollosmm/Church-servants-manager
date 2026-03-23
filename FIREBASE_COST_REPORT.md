# Firebase Cost Report
**Project:** church-6eb05
**Estimated Monthly Cost Before:** $150 (Projected at scale)
**Estimated Monthly Cost After:** $30 (80% reduction target)

## 🔴 Critical — Fix Immediately
| # | File | Line | Issue | Fix Strategy | Est. Savings |
|---|------|------|-------|--------------|-------------|
| 1 | `student_query_service.dart` | 315 | Unbounded roster snapshots | Add `.limit(100)` + Local Caching | 60% |
| 2 | `attendance_repository.dart` | 335 | Real-time marks on entire list | Add `.limit(200)` + Delta processing | 50% |
| 3 | `attendance_repository.dart` | 419 | Unbounded history snapshots | Add `.limit(20)` + Lazy loading | 40% |

## 🟡 Warnings — Fix This Sprint
| # | File | Line | Issue | Fix Strategy | Est. Savings |
|---|------|------|-------|--------------|-------------|
| 4 | `attendance_repository.dart` | 177 | Redundant server fetch | Local TTL Caching (10 min) | 15% |
| 5 | `servant_data_repository.dart` | 278 | Real-time user list | Replace with one-time `.get()` | 10% |
| 6 | `team_repository.dart` | 201 | Real-time class list | Replace with one-time `.get()` | 10% |

## 🟢 Already Optimized
- `AttendanceRepository.getSessionById` (uses targeted document fetch)
- `AuthUserProfileStore` (uses Source.cache where appropriate)

## 📋 Fix Plan
### Phase A — Zero-Risk Fixes (caching, .limit, field masking)
- [ ] Add `Hive` or `SharedPreferences` caching for one-time fetches (Teams, Students).
- [ ] Implement `.limit()` on all roster and history queries.
- [ ] Enable Firestore Offline Persistence (verified in Flutter SDK).

### Phase B — Architecture Fixes (aggregation docs, replace streams)
- [ ] Replace `snapshots()` with one-time `.get()` for static lists (Servants, Teams).
- [ ] Implement Aggregation Documents for team stats (Total Present/Absent).

### Phase C — Infrastructure Fixes (Data Bundles, Cloud Functions)
- [ ] Use Cloud Functions for fan-out operations during session closure.
