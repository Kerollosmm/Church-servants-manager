# Phase 3 — Attendance Sessions: Task Checklist

## P3-T1 · Fix Failing Repo Tests (3 cases)
- [ ] P3-T1.1 Open `test/features/attendance/data/repos/attendance_repository_test.dart`
- [ ] P3-T1.2 Identify test #1: idempotent mark — fix mock to return existing doc with `markedAt` field on second `.get()` call
- [ ] P3-T1.3 Identify test #2: late-status preservation — fix mock to return existing `markedAt` on update path
- [ ] P3-T1.4 Identify test #3: assess and fix
- [ ] P3-T1.5 Run `flutter test test/features/attendance/data/repos/attendance_repository_test.dart` — all pass

## P3-T2 · Session Widget Atoms
- [ ] P3-T2.1 Create `session_status_badge.dart` — pill widget: "مفتوح" (green) / "مغلق" (grey) / "منتهي" (orange)
- [ ] P3-T2.2 Create `session_list_tile.dart` — title, date/time, status badge, student count, created-by
- [ ] P3-T2.3 Create `session_date_group_header.dart` — sticky date label formatted as "الجمعة، 27 مارس 2026"
- [ ] P3-T2.4 Create `session_create_form.dart` — team dropdown, date picker, time picker, duration dropdown, title field

## P3-T3 · Implement AttendanceSessionCreateScreen
- [ ] P3-T3.1 Wrap with `BlocProvider<SessionAdminCubit>` (from `GetIt`)
- [ ] P3-T3.2 Render `SessionCreateForm`
- [ ] P3-T3.3 Validate: team selected, date not null, duration > 0
- [ ] P3-T3.4 On submit: dispatch `createSession` via cubit
- [ ] P3-T3.5 `BlocListener`:
  - loading → show button loading state
  - success → pop + `SnackBar('تم إنشاء الجلسة بنجاح')` + optionally push to `attendanceTaking`
  - failure → show `SnackBar` with error message
- [ ] P3-T3.6 Conflict error → distinct message: "يوجد جلسة مفتوحة في نفس الوقت"
- [ ] P3-T3.7 Widget test: empty team field blocks submit

## P3-T4 · Implement AttendanceHistoryScreen
- [ ] P3-T4.1 Receive `teamId` from route args (or pull from cubit if single-team servant)
- [ ] P3-T4.2 Subscribe to `watchSessionsForTeam(teamId)` via cubit
- [ ] P3-T4.3 Group sessions by `dateKey` into ordered `Map<String, List<AttendanceSession>>`
- [ ] P3-T4.4 `CustomScrollView` with `SliverStickyHeader` per date group (or simple `ListView` sections)
- [ ] P3-T4.5 Each tile → `SessionListTile` with `SessionStatusBadge`
- [ ] P3-T4.6 On tap open session → push `attendanceTaking` with `AttendanceTakingArgs`
- [ ] P3-T4.7 On tap closed/expired session → push `attendanceTaking` in view-only mode
- [ ] P3-T4.8 Admin: "Close" icon button on open session tiles → call `closeSession` via cubit + confirm dialog
- [ ] P3-T4.9 Servant: "Close" icon hidden
- [ ] P3-T4.10 Empty state when no sessions
- [ ] P3-T4.11 Widget test: session list renders; close button visible only for admin role

## P3-T5 · Role-Policy UI Enforcement
- [ ] P3-T5.1 Pass `AuthUser` role to `AttendanceHistoryScreen` (or read from `AuthBloc` in context)
- [ ] P3-T5.2 Close button conditional: `user.role == UserRole.admin`
- [ ] P3-T5.3 Confirm dialog before close: "هل تريد إغلاق هذه الجلسة؟ لن تتمكن من تعديل الحضور بعد ذلك."

## P3-T6 · Final Gate
- [ ] `flutter analyze` — 0 issues
- [ ] 3 previously failing repo tests now pass
- [ ] `flutter test test/features/attendance/` — all pass
- [ ] Manual smoke: create session → appears in history → admin closes → status updates
