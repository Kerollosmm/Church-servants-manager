# AGENT.md — CSMS Agent Guide (Technical + Workflows)

> **Audience**: AI coding agents and senior developers working on the Church Servants Management System (CSMS).
> **Focus**: Concrete app behavior, user flows, functions, and how features interact with Firebase + Hive.

---

## 0. Agent Operating Protocol (Mandatory First Steps)

**CRITICAL: You MUST follow these steps before performing ANY other action on a task.**

### 1. Identify and Review Skills
Jules does not support skills natively. You MUST manually discover them in the repository:
1. **List the `skills/` directory** immediately.
2. **Find matches** for your current task (e.g., UI, Database, Firebase, Architecture).
3. **Read the `SKILL.md`** files for all relevant skills.
4. **Always start with `skills/find-skills/SKILL.md`** to ensure comprehensive discovery.

### 2. Acknowledge and Apply
- State clearly which skills you are applying.
- Treat instructions in `SKILL.md` files as **mandatory project rules**.
- If a skill contradicts a general rule, the **skill takes precedence**.

---

## 1. System Summary (What You Are Building)

**CSMS (Church Servants Management System)** is a unified Flutter mobile app for church servants and students that:
- Authenticates users with Firebase Auth.
- Stores data locally in Hive so everything works offline.
- Syncs attendance and results with Firestore when internet is available.
- Enforces strict role-based access (Servant vs Admin vs Student).

You are not building a generic app. You are implementing:
- **Attendance Management** (multi-servant, offline-first, barcode-ready).
- **Results Viewing** (multi-term history, student-only visibility).
- **Admin Operations** (user management, results upload, sync status). [file:1][file:2][file:8]

---

## 2. High-Level Technical Architecture

### 2.1 Layers

```
Flutter UI (Pages + Widgets)
│
├── Presentation: BLoC (Events → Use Cases → States)
├── Domain: Entities + Use Cases + Repository Interfaces
├── Data: Models + Mappers + Local/Remote Data Sources + Repository Impl
│
├── Local Store: Hive (offline-first, encrypted where needed)
├── Secure Store: flutter_secure_storage (auth session, tokens)
└── Cloud: Firebase Auth + Firestore + Cloud Functions
```

**Key Rules:**
- All feature logic goes through **Use Cases**.
- Repositories hide where data comes from (Hive vs Firestore).
- Data sources handle **one thing**: remote (Firebase) or local (Hive/SecureStorage).
- No direct Firebase calls from UI or BLoC.
- No global singletons in domain layer; use constructor injection. [file:8]

### 2.2 Core Services

- `FirebaseService` — wraps Firebase initialization, returns `FirebaseAuth` and `FirebaseFirestore` instances.
- `HiveService` — initializes Hive, registers adapters, opens boxes.
- `SecureStorageService` — simple read/write/delete string API around `flutter_secure_storage`.
- `ConnectivityService` — online/offline detection via `connectivity_plus`.
- `SyncService` — orchestrates background sync of pending records (attendance, results cache) to Firestore.

These are registered in `dependency_injection.dart` and injected into repositories and use cases. [file:8]

---

## 3. User Types and Their Workflows

### 3.1 Servant

**Goals:**
- Log in.
- Mark attendance for their group (manual + barcode) even when offline.
- See high-level attendance reports for their group.

**Primary Screens:**
- `LoginPage`
- `HomePage` (tabs: Attendance, Results, Profile)
- `AttendanceListPage`
- `BarcodeScannerPage`
- `AttendanceReportPage`

**Core Servant Flows:**

#### Flow S1 — Servant Login

1. Servant opens app → `SplashPage` displayed.
2. `CheckSessionUseCase` checks secure storage for cached `UserModel`.
3. If no valid session → navigate to `LoginPage`.
4. Servant enters `username` + `password` and taps **Login**.
5. `AuthBloc` fires `LoginRequested(username, password)`.
6. `LoginUseCase` calls `AuthRepository.login(...)`:
   - Remote: `AuthRemoteDataSource.login()` uses `FirebaseAuth.signInWithEmailAndPassword()`.
   - Fetch role and metadata from Firestore `users/{uid}`.
   - Map to `UserModel` → save to secure storage via `AuthLocalDataSource.saveSession()`.
   - Convert to `UserEntity` (domain) via `UserMapper.toDomain()`.
7. On success, `AuthBloc` emits `AuthAuthenticated(user)` and navigation goes to `HomePage`.

**Important Behaviors:**
- Username is converted to an email format internally (e.g. `username@csms.church`).
- No password is stored locally. Only session token + small user profile are in secure storage.
- If offline and cached session exists, user can still enter app with last known role (grace period). [file:1][file:8]

#### Flow S2 — Servant Marks Attendance (Manual, Offline-First)

1. Servant opens **Attendance** tab.
2. `AttendanceBloc` dispatches `LoadTodaySession()`.
3. `GetTodayServantsUseCase` fetches servants list:
   - First from Hive via `ServantsLocalDataSource.getCachedServants()` → instant UI.
   - If online, remote Firestore `servants` collection is fetched and cache is updated in background.
4. UI shows list of servants with status icon (`present/absent/late`).
5. Servant taps a servant row → `MarkPresentEvent(servantId, sessionId)`.
6. `MarkPresentUseCase` creates or updates an `AttendanceRecordEntity`:
   - `recordId` = deterministic ID (e.g. `"$sessionId-$servantId"` or UUID).
   - Sets `status = present`, `syncStatus = pending`, `clientUpdatedAt = now`.
7. `AttendanceLocalDataSource.saveRecord(record)` writes to Hive immediately.
8. UI state updates instantly (status icon → green, checkmark) **without any network call**.

Later, when connectivity is available:
- `SyncService` finds all `AttendanceRecordModel` with `syncStatus == pending` and uploads them via a Firestore batch to `attendanceRecords/{recordId}`.
- On success, it updates those records in Hive to `syncStatus = synced` and `serverUpdatedAt = now`.

**Key guarantees:**
- Servant never waits on the network to mark attendance.
- There is exactly one Firestore record per `(sessionId, servantId)` because `recordId` is used as the document ID.
- Network failure only delays sync; it never blocks local updates. [file:1][file:8]

#### Flow S3 — Servant Uses Barcode Scanner

1. From `AttendanceListPage`, servant taps **Scan Barcode** button.
2. Navigate to `BarcodeScannerPage` which uses `flutter_barcode_scanner`.
3. On successful scan, barcode string is parsed into a `servantId`.
4. Local-only lookup: `ServantsLocalDataSource.getCachedServants()` is used to find that servant.
5. If found → same `MarkPresentUseCase` as manual tap (Flow S2) is executed.
6. UI shows confirmation (snackbar, sound, visual highlight of the row in the list).
7. If not found → show error message and optionally navigate back to search.

Barcode flow never requires Firestore at scan time; it depends entirely on locally cached servants. [file:1]

#### Flow S4 — Servant Views Attendance Report

1. Servant opens **Attendance Report** tab or page.
2. `AttendanceReportBloc` sends `LoadAttendanceSummary(dateRange)`.
3. Use cases aggregate data from Hive:
   - `GetAttendanceRecordsUseCase(dateRange)` returns list from `attendanceBox`.
   - Filter by servant group and date range.
4. UI renders:
   - Per-servant attendance rate (%).
   - Trends over time (basic charts in Flutter if implemented).
5. If online, remote Firestore queries can enrich data (e.g. for very long history) but local data is always the initial source.

Servants never see other groups beyond what their role allows; any additional filtering is enforced by Firestore rules on remote reads. [file:1][file:2]

---

### 3.2 Student

**Goals:**
- View their own attendance.
- View their own results across multiple terms.

**Primary Screens:**
- `StudentHomePage` (or same home with different tab visibility).
- `ResultsListPage`
- `TermDetailPage`
- `MyAttendancePage`

**Flows:**

#### Flow ST1 — Student Views Results

1. Student opens app and logs in (same auth flow, but `UserRole.student`).
2. Goes to **Results** tab (only visible to students or servants with read permission).
3. `ResultsBloc` triggers `FetchTerms()` which uses `GetAllTermsUseCase`.
4. `ResultsRepositoryImpl`:
   - Reads from Hive `resultsBox` for `servantId == currentUser.id` for instant display.
   - If online, queries Firestore `results/{servantId}/terms` and merges into cache.
5. UI shows a list of terms (e.g. `Fall 2023`, `Spring 2024`) with date and overall average.
6. On selecting a term:
   - `GetTermDetailsUseCase` returns subjects/scores from Hive/Firestore.
   - `TermDetailPage` displays subject-by-subject scores and a visual overview (e.g. chart, badges).

Student can operate entirely offline with last-synced results; new terms appear after next successful sync. [file:1][file:2]

#### Flow ST2 — Student Views Personal Attendance

1. Student opens **My Attendance** page.
2. `MyAttendanceBloc` calls `GetAttendanceRecordsUseCase(studentId: currentUser.id)`.
3. Data comes from Hive as primary source; Firestore enriches when online.
4. UI renders:
   - Calendar or list per session with `present/absent/late` flags.
   - Attendance percentage summary.

Firestore rules ensure student can only read their own records (`request.auth.uid == studentUid`). [file:2]

---

### 3.3 Admin

**Goals:**
- Manage servants/students.
- Upload results in bulk.
- Monitor sync status and conflicts.
- View reports and audit logs.

**Primary Screens:**
- `AdminDashboardPage`
- `UserManagementPage`
- `ResultsUploadPage`
- `SyncStatusPage`
- `AdminReportsPage`

**Key Admin Flows:**

#### Flow A1 — Manage Users

1. Admin opens **User Management**.
2. `AdminBloc` triggers `LoadUsers()`.
3. `AdminRepository` reads from Firestore `users` collection (admins only).
4. Admin can:
   - Create new servant: fill form → Firestore `users/{uid}` + Firebase Auth user created via Cloud Function.
   - Edit details: updates Firestore fields (role, department, isActive).
   - Deactivate user: sets `isActive = false` so login fails for that user.
5. Every action writes an entry into `auditlogs` with `userId`, `action`, `resource`, `timestamp`. [file:1][file:2]

#### Flow A2 — Upload Results via CSV

1. Admin opens **Results Upload** page.
2. Selects CSV file (e.g. from local filesystem or cloud) with columns: `servantId, subject1, subject2, ...`.
3. App parses CSV locally and shows preview table.
4. On **Publish**, app calls Cloud Function:
   - `publishResults(termName, date, rows)`.
   - Function validates data, then for each row writes `results/{servantId}/terms/{termId}` with scores and average.
5. After writes, Firestore real-time listeners on servant devices update their Hive caches and show **New results available** indicator.

**Agent note:** The Cloud Function API shape must align with the Firestore schema used in the mobile app. [file:1][file:2]

#### Flow A3 — Monitor Sync Status

1. Admin opens **Sync Status**.
2. `SyncStatusBloc` queries both:
   - Local: `sync_meta` box (what is pending or failed on this device).
   - Remote: Firestore summary (optional) of last sync per device / per servant.
3. UI shows:
   - Count of `pending`, `synced`, `failed` records.
   - Latest sync timestamp.
4. Admin can tap **Sync Now** → triggers `SyncAttendanceUseCase` and `SyncResultsUseCase` to run `SyncService` immediately.

Conflicts (different statuses for same `(sessionId, servantId)`) are surfaced with options to pick winning version; technically, base rule is **last-write-wins** using timestamps. [file:1]

---

## 4. Offline-First Behavior (Technical Rules)

### 4.1 Reads

- Always read **Hive first**. Use Firestore to refresh data only when online.
- Repository pattern:

```dart
Future<List<ServantEntity>> fetchServants() async {
  try {
    final remoteModels = await remoteDataSource.fetchServants();
    await localDataSource.cacheServants(remoteModels);
    return ServantMapper.toDomainList(remoteModels);
  } catch (_) {
    final cached = await localDataSource.getCachedServants();
    if (cached.isNotEmpty) {
      return ServantMapper.toDomainList(cached);
    }
    rethrow;
  }
}
```

### 4.2 Writes

- Attendance writes go **local first** with `syncStatus = pending`.
- Sync engine later pushes to Firestore.
- Results writes for students are server-originated (Cloud Functions) — mobile app only reads them.

### 4.3 Conflict Resolution

- `clientUpdatedAt` and `serverUpdatedAt` are used.
- When a remote record is newer than local → local is overwritten.
- When local is newer and `syncStatus = pending` → local wins and is pushed.
- Admin can manually override via Sync UI if needed. [file:1]

---

## 5. Data Models & Required Fields

### 5.1 AttendanceRecordModel (Hive + Firestore)

```dart
@HiveType(typeId: 2)
class AttendanceRecordModel {
  @HiveField(0)
  final String recordId;          // Firestore doc ID
  @HiveField(1)
  final String sessionId;
  @HiveField(2)
  final String studentId;
  @HiveField(3)
  final String studentUid;
  @HiveField(4)
  final String servantId;
  @HiveField(5)
  final String status;            // 'present' | 'absent' | 'late'
  @HiveField(6)
  final String? note;
  @HiveField(7)
  final String syncStatus;        // 'pending' | 'synced' | 'failed'
  @HiveField(8)
  final DateTime clientUpdatedAt;
  @HiveField(9)
  final DateTime? serverUpdatedAt;
}
```

**Important:** `recordId` must be used as the Firestore doc ID so re-sending the same record is safe (idempotent). [file:1]

### 5.2 UserModel (Auth)

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel {
  final String id;          // Firebase UID
  final String username;
  final int roleIndex;      // index into UserRole enum
  final DateTime createdAt;
  final DateTime? lastLogin;
}
```

Roles are handled via `UserRole.values[roleIndex]` in domain. [file:8]

---

## 6. Agent Implementation Priorities

When you (the agent) generate or refactor code, always:

1. **Preserve offline-first behavior.**
   - Never make UI depend on Firestore availability for core flows (attendance marking, results viewing).

2. **Avoid duplicate writes to Firestore.**
   - Always use `recordId` as the document ID.

3. **Minimize reads/writes.**
   - Use batch operations for sync.
   - Avoid re-fetching large collections unnecessarily; rely on Hive cache.

4. **Respect roles in UI + data layer.**
   - Hide admin screens for non-admins.
   - Never trust the client-only role; Firestore rules must still enforce.

5. **Keep Clean Architecture boundaries.**
   - UI ↔ BLoC ↔ Use Cases ↔ Repositories ↔ Data Sources.
   - Do not let Firebase types leak into domain/entities.

6. **Make everything testable.**
   - Provide abstractions for repositories and services.
   - No direct static calls in business logic.

---

## 7. Quick Checklist Per Feature

### Auth Feature
- [ ] `LoginUseCase` uses `AuthRepository` only.
- [ ] `AuthRepositoryImpl` composes remote + local data sources.
- [ ] Secure storage only holds minimal session JSON, not password.
- [ ] Session check works offline with grace period.

### Servants Feature
- [ ] Servants list uses offline cache, then online refresh.
- [ ] No UI logic inside repository or model.
- [ ] `isSelected` style fields are excluded from JSON/Hive serialization.

### Attendance Feature
- [ ] `MarkPresentUseCase` writes to Hive and sets `syncStatus = pending`.
- [ ] Sync engine batches records by session.
- [ ] Conflict resolution uses timestamps.
- [ ] Records use `recordId` as Firestore doc ID.

### Results Feature
- [ ] Results read from Hive first.
- [ ] Firestore used to refresh only when online.
- [ ] Timeline UI orders terms by date descending.

### Admin Feature
- [ ] All admin-only calls guarded by role checks + Firestore rules.
- [ ] Results upload handled by Cloud Function, not directly by app.
- [ ] Audit logs written for critical operations.

---

## 8. Agent Rules (Critical — Never Violate)

### Auth & Security
- **All repository write methods MUST call auth/role verification BEFORE any Firestore mutation.** Never rely solely on Firestore security rules — client-side defense-in-depth is required.
- **When creating auth/permission helpers, copy the authoritative implementation's logic verbatim.** Do NOT simplify — every condition (archived check, role bypass, `effectiveAssignedTeamIds`) exists for a reason.
- **Dead code validation methods are security gaps.** If `assertCanX` exists, verify it is called by all relevant write methods.
- **Audit fields (`archivedByUserId`, `restoredByUserId`) MUST accept the performing user's UID.** Never hardcode `'system'` — it destroys audit trail integrity.

### Architecture
- **Never delete domain-layer interface files** (`I*Repository`). They are the contract enabling testability and implementation swapping. If they seem redundant, they still serve Dependency Inversion.
- **BLoCs/Cubits/UseCases MUST depend on domain interfaces**, never concrete data-layer classes.
- **`cloud_firestore` types MUST NOT leak into domain or presentation layers.** Use abstractions in repository public APIs.

### Firestore Rules
- **Never compare `request.time` (server clock) against client-written `DateTime.now()` without a grace window.** Add `duration.value(5, 'm')` tolerance for clock skew.
- **Student document IDs are auto-generated, NOT Auth UIDs.** Rules checking `studentId == callerUid()` will fail. Use `get(/Students/$(studentId)).data.get('uid', '') == callerUid()` instead.

### Firestore Cost
- **Always use server-side filtering** (`.where('isArchived', isEqualTo: false)`) instead of client-side filtering. Full collection scans waste reads.
- **Batch reads where possible.** N+1 individual `.get()` calls should use `whereIn` chunked to 10 or collection group queries.

---

*This AGENT.md is intentionally focused on technical behavior and user workflows so an AI agent can reason about how to implement, modify, or test the system without re-reading long conceptual documents.*
