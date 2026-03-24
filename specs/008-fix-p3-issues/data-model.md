# Data Model: Fix P3 Backlog Issues

This document defines new data structures and state transitions for the P3 fixes.

## 1. Pagination State (Generic)

Applied to `StudentDataState` and `ServantDataState`.

| Field | Type | Description |
|-------|------|-------------|
| `items` | `List<T>` | Accumulated items from all loaded pages. |
| `lastDocument` | `DocumentSnapshot?` | Cursor for the next page. Null if no more data. |
| `isLoadingMore` | `bool` | True when a subsequent page is being fetched. |
| `hasReachedMax` | `bool` | True when Firestore returns fewer items than the limit. |

**Transitions**:
- `Initial` -> `Loading` (first page)
- `Loaded` -> `LoadingMore` (user scrolled to bottom)
- `LoadingMore` -> `Loaded` (append new items, update cursor)

## 2. Connectivity State

| Field | Type | Description |
|-------|------|-------------|
| `isOffline` | `bool` | True if no internet connection is detected. |

## 3. Attendance Session Timer State

| Field | Type | Description |
|-------|------|-------------|
| `remainingTime` | `Duration` | Time left until session expiry. |
| `showWarning` | `bool` | True if `remainingTime` < 10 minutes. |
| `isExpired` | `bool` | True if `remainingTime` <= 0. |

**Transitions**:
- Update every 1 second via `Timer.periodic`.
- Emit state only when `showWarning` or `isExpired` status changes, or when the timer UI needs to refresh the displayed seconds.
