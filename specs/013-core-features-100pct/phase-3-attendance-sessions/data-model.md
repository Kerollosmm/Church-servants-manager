# Phase 3 — Attendance Sessions: Data Model

## AttendanceSession (existing — reference only)
```
AttendanceSession {
  id: String              // deterministic: dateKey_ms_slug
  teamId: String
  teamNameSnapshot: String?
  title: String?
  dateKey: String         // 'YYYY-MM-DD'
  startsAt: DateTime
  endsAt: DateTime
  durationMinutes: int
  createdByUserId: String
  createdByName: String
  createdAt: DateTime
  updatedAt: DateTime
  isClosed: bool
  studentIdsSnapshot: List<String>
  studentNameSnapshots: Map<String, String>
}

// Computed helpers (no Firestore field):
isOpenAt(DateTime now): bool
isEffectivelyClosedAt(DateTime now): bool
```

## Session Lifecycle State Machine
```
                ┌──────────────────────────────────┐
                │           OPEN SESSION             │
                │  isClosed=false                   │
                │  isOpenAt(now) = startsAt<=now    │
                │               && endsAt > now     │
                └────────────┬─────────────────────┘
                             │ closeSession() [admin only]
                             ▼
                ┌──────────────────────────────────┐
                │          CLOSED SESSION            │
                │  isClosed=true                    │
                │  marks are locked (no writes)     │
                └──────────────────────────────────┘
                             │ (time expires, no close)
                             ▼
                ┌──────────────────────────────────┐
                │       EXPIRED (effectively closed) │
                │  isClosed=false, endsAt < now     │
                │  isEffectivelyClosedAt=true       │
                └──────────────────────────────────┘
```

## Firestore Path
`Classes/{teamId}/attendanceSessions/{sessionId}`

## Session Create Form Input Contract
```
SessionCreateFormData {
  teamId: String                   // required — dropdown selection
  teamNameSnapshot: String         // denormalized at creation
  startsAt: DateTime               // date + time pickers
  durationMinutes: int             // slider or dropdown: 30/45/60/90/120
  title: String?                   // optional label
}
```

## Servant Role Policy (documented decision)
| Action | Admin | Servant | Student |
|--------|-------|---------|---------|
| Create session | ✅ | ✅ | ❌ |
| View session list | ✅ | ✅ | ❌ |
| Take attendance | ✅ | ✅ | ❌ |
| Close session | ✅ | ❌ | ❌ |
| View own history | ❌ | ❌ | ✅ |
