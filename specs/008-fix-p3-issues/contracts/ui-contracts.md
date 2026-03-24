# UI Contracts: Fix P3 Backlog Issues

This document defines the interface and behavior for new global UI components.

## 1. `OfflineIndicator` Widget

**Location**: `lib/core/widgets/offline_indicator.dart`

**Properties**:
- `child`: The main content of the screen.

**Behavior**:
- Wraps the screen content.
- Listens to `ConnectivityService.isOffline` stream.
- When `isOffline` is true:
    - Display a `Container` with `AppColors.errorContainer` background.
    - Text: "You are offline. Showing cached data."
    - Position: Top-anchored (below AppBar if possible, or floating).
    - Animation: Slide in from top.
- When `isOffline` is false:
    - Hide indicator with slide-out animation.

## 2. `SessionExpiryBanner` Widget

**Location**: `lib/features/attendance/presentation/widgets/session_expiry_banner.dart`

**Behavior**:
- Listens to `AttendanceSessionTimerCubit`.
- Visible only when `showWarning` is true.
- When visible:
    - Display remaining time: "Session expires in MM:SS".
    - Background: `AppColors.warningContainer`.
    - Border: 1px stroke of `AppColors.warning`.
- When `isExpired` is true:
    - Text changes to: "Session Expired".
    - Background: `AppColors.errorContainer`.

## 3. `PaginatedListView` (Pattern)

**Behavior**:
- Uses `ScrollController`.
- Shows a `CircularProgressIndicator` at the bottom of the list when `isLoadingMore` is true.
- Displays "No more items" or similar when `hasReachedMax` is true and list is long.
- Triggers `onLoadMore` callback when `maxScrollExtent` is approached.
