# Phase 4 — Attendance Recording: Research Notes

## R1 — Real-Time Roster Update Pattern
**Decision**: `AttendanceTakingCubit` subscribes to `watchSessionRosterSnapshot()` which already combines session + marks + clock streams via `Rx.combineLatest3`. Each emission replaces the full roster list in state.  
**Rationale**: No manual re-fetch needed. Marks pressed by any servant immediately appear for all watchers.  
**UI concern**: Avoid full list rebuild on every mark. Use `ValueKey(item.studentId)` on each tile so Flutter's diffing preserves scroll position.

## R2 — Optimistic Mark Updates
**Decision**: No optimistic update in v1. Show loading indicator on the tile being marked, then reflect server confirmation.  
**Rationale**: Firestore real-time stream latency is <300ms on good connection. Optimistic state adds complexity without meaningful UX benefit for this class size (typically 10–40 students).

## R3 — Closed Session View-Only Mode
**Decision**: When `AttendanceRosterItem.canEdit == false`, `AttendanceMarkButtons` renders as `null` (no buttons). Session header shows "مغلق" badge.  
**Rationale**: `canEdit` is already computed in `_buildRosterSnapshot` based on `session.isOpenAt(now)`. No additional logic needed.

## R4 — AttendanceRecordModel Purpose
**Rationale**: The audit noted `attendance_record_model.dart` is empty. This model serves as a serializable local record for future Hive caching. For Phase 4, implement it as a pure Dart class (no code-gen overhead). Hive adapter generation is deferred to the offline sprint.

## R5 — Student Attendance Stats Calculation
**Decision**: Compute stats client-side in `StudentAttendanceCubit` after stream emission:
```dart
final total = items.length;
final attended = items.where((i) =>
  i.effectiveStatus == EffectiveAttendanceStatus.present ||
  i.effectiveStatus == EffectiveAttendanceStatus.late
).length;
final percentage = total == 0 ? 0.0 : attended / total;
```
**Rationale**: Matches existing `StudentAttendanceCubit` computation pattern.

## R6 — Bulk Mark Button Placement
**Decision**: Floating action button (FAB) labeled "تحديد الجميع حاضرين". Only visible when `session.isOpenAt(now)` and there are unmarked students. Pressing shows a confirm `AlertDialog` then calls repo.  
**Rationale**: Guards against accidental bulk marks.
