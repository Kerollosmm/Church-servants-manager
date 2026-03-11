# Data Flow

## Authentication Flow

```
App Launch
  └─ main() calls Firebase.initializeApp() + configureDependencies()
  └─ ChurchApp mounts AuthBloc
  └─ AuthBloc receives AuthEventCheckStatus
       │
       ├─ Reload Firebase Auth user (FirebaseAuthProvider.reloadUser)
       ├─ Fetch Firestore Users/{uid} (AuthUserProfileStore)
       │
       ├── null user ──────────────────► AuthUnauthenticated ──► LoginScreen
       ├── user.isArchived == true ─────► AuthArchived ──► ArchivedAccountScreen
       ├── !user.isEmailVerified ───────► AuthNeedsVerification ──► VerifyEmailScreen
       └── ok ──────────────────────────► AuthAuthenticated
              │
              └─ RoleUserRoute reads user.role
                   ├─ admin   → AdminDashboardScreen
                   ├─ servant → ServantDashboardScreen
                   └─ student → StudentProfileScreen
```

**Ongoing session monitoring:** `AuthBloc` subscribes to `FirebaseAuth.authStateChanges`. Any Firebase token revocation or sign-out emits `_AuthEventSessionChanged`, which re-evaluates auth state without user interaction.

---

## Student CRUD Flow (Admin/Servant)

```
User taps "Add Student"
  └─ Navigates to StudentEditScreen (via AppRouter, injects StudentDataBloc)
  └─ StudentEditScreen builds form, user fills fields
  └─ User submits
       │
       └─ StudentDataBloc.add(StudentDataEventSave(model))
            │
            └─ CanMutateStudentUseCase.call(actor, student) → permission check
            └─ StudentDataRepository.saveStudent(model)
                 │
                 └─ Writes to Firestore: Students/{studentId}
                 └─ StudentLinkedUserSyncService.syncIfNeeded(model)
                      │
                      └─ If student has a linked Users/{uid}, update Users doc
                           (name, email sync)
```

---

## Attendance Session Create Flow

```
Servant/Admin navigates to AttendanceSessionCreateScreen
  └─ Selects team, date, start time, duration, optional title
  └─ Submits form
       │
       └─ AttendanceSessionAdminCubit.createSession(...)
            │
            └─ AttendanceRepository.createSession(...)
                 │
                 ├─ assertUserCanManageAttendance (permission check)
                 ├─ _assertTeamIsActive (reads Classes/{teamId})
                 ├─ StudentQueryService.getStudentsByClass(teamId) → roster
                 ├─ Build candidate AttendanceSession (with studentIdsSnapshot)
                 ├─ Query existing open sessions for overlap / duplicate check
                 └─ Firestore.runTransaction:
                      └─ Verify no existing doc at session ID
                      └─ Write Classes/{teamId}/attendance_sessions/{sessionId}
```

---

## Attendance Taking Flow (Real-Time)

```
Servant opens AttendanceTakingScreen
  └─ AttendanceTakingCubit.startWatching(teamId, sessionId)
       │
       └─ AttendanceRepository.watchSessionRosterSnapshot(teamId, sessionId)
            │
            └─ Rx.combineLatest3(
                 watchSessionById(...)       → session document stream
                 _watchStudentsByIds(...)    → students stream (chunked whereIn)
                 _watchClock()               → 15-second ticker
               )
            └─ Emits AttendanceRosterSnapshot on every change
```

```
Servant marks student
  └─ AttendanceTakingCubit.markPresent(studentId)
       │
       └─ AttendanceRepository.markStudentPresent(...)
            │
            ├─ assertUserCanManageAttendance
            ├─ _getRequiredSession → validates session still exists
            ├─ _assertStudentInSession → student is in the snapshot
            ├─ _assertSessionWritable → session open at current time
            └─ Firestore.set(mergeTrue): marks/{studentId}
                 (preserves original markedAt; updates updatedAt)
```

---

## Servant Assignment to Team

```
Admin opens TeamMembersScreen
  └─ Taps "Assign Servant"
  └─ AssignServantDialog shown
      └─ AssignServantOptionsCubit loads available servants (ServantDataRepository)
      └─ Admin selects a servant
           │
           └─ AdminTeamService.assignServant(teamId, servantId)
                │
                ├─ Update Classes/{teamId}: assignedServantId, assignedServantName
                └─ AdminTeamMembershipService:
                     ├─ Add teamId to Users/{servantId}.assignedTeamIds
                     └─ (Remove from previous servant's assignedTeamIds if applicable)
```

---

## Role-Based Data Visibility

```
Firestore Query (e.g., Students)
  └─ Client sends query
       │
       └─ Firestore evaluates security rules:
            ├─ isAdmin() → full collection access
            ├─ servantCanReadStudent() →
            │    (student.group == callerUser.groupId) OR
            │    (student.classId in callerUser.assignedTeamIds)
            └─ resource.data.uid == callerUid() → student reads own doc
```

The server enforces these rules independently of the client. Even if client-side permission checks are bypassed, Firestore will reject unauthorised reads/writes.

---

## Offline Write Queue

```
Network unavailable
  └─ Flutter writes to Firestore SDK
       └─ SDK queues write in local LevelDB cache
       └─ UI observes locally-cached stream (optimistic)
  └─ Network restored
       └─ SDK replays queued writes in order
       └─ Server responds → stream updates with server-authoritative data
```

Offline writes are transparent to the application code. Failures (e.g., rule violations discovered on server replay) surface as stream errors, which the repository maps to `AttendanceFailure` or equivalent.
