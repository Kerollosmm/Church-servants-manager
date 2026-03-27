# Phase 3 — Attendance Sessions: Research Notes

## R1 — Failing Repo Test Root Causes
**Idempotent mark write**: `_writeMark` uses `markRef.set(..., SetOptions(merge:true))`. On second call for same student, `markedAt` must be preserved using `existingMarkedAt ?? FieldValue.serverTimestamp()`. Current test may be using a mock that doesn't return the existing doc. Fix: ensure mock returns existing doc snapshot with `markedAt` populated on second call.

**Late-status preservation**: Same `_writeMark` flow — if a student was previously marked `present` and is now marked `late`, `markedAt` must stay as the original timestamp (first mark time). The code already does `existingMarkedAt ?? FieldValue.serverTimestamp()`. Fix: verify mock wiring; the existing field must be returned from mock `.get()`.

**Third case**: Assess line-by-line against test file before fixing.

## R2 — Date-Grouped Session List
**Decision**: Group sessions by `session.dateKey` (`'YYYY-MM-DD'`) client-side after streaming. Use a `Map<String, List<AttendanceSession>>` keyed by date, sorted descending.  
**Widget pattern**:
```dart
SliverStickyHeader(
  header: SessionDateGroupHeader(dateKey: key),
  sliver: SliverList(delegate: SliverChildBuilderDelegate(...)),
)
```
**Dependency**: `flutter_sticky_header` — already in pubspec or add it.

## R3 — Team Selection in Create Form
**Decision**: Dropdown populated from `AdminDashboardCubit` team list (already streams team data). Pre-select if servant has a `teamId` assigned.

## R4 — Duration Picker
**Decision**: `DropdownButtonFormField<int>` with options `[30, 45, 60, 90, 120]` minutes. Simple and accessible.

## R5 — Date + Time Pickers
**Decision**: Flutter built-in `showDatePicker` + `showTimePicker`. Combine into `DateTime` before passing to cubit. Minimum: today. Maximum: 7 days out (prevent far-future session spam).
