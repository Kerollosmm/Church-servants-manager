# Research: Fix P3 Backlog Issues

This document consolidates research findings for the P3 backlog items.

## 1. Firestore Pagination for Large Lists

**Objective**: Implement efficient cursor-based pagination for student and servant lists to handle 500+ items without memory pressure.

**Findings**:
- Existing repositories (`StudentDataRepository`, `ServantDataRepository`) already have methods that accept `limit` and `lastDocument`.
- **Decision**: Update the corresponding Cubits (`StudentDataBloc`, `ServantDataCubit`) to maintain a `List<DocumentSnapshot>` for cursors and append new pages to the state.
- **UI Strategy**: Use `ScrollController` with a listener to trigger "load more" when the user reaches 80% of the list height.
- **Rationale**: Cursor-based pagination is the standard for Firestore to ensure consistency and cost-efficiency.
- **Alternatives considered**: Offset-based pagination (not supported/efficient in Firestore).

## 2. App-wide Network Connectivity Awareness

**Objective**: Show a non-intrusive offline indicator when the device loses internet connection.

**Findings**:
- No connectivity package currently in `pubspec.yaml`.
- **Decision**: Add `connectivity_plus` package.
- **Service Pattern**: Create a `ConnectivityService` that wraps `Connectivity().onConnectivityChanged` and exposes a `Stream<bool> isOffline`.
- **Registration**: Register as a lazy singleton in `injection.dart`.
- **UI Pattern**: Create a `ConnectivityWrapper` widget in `core/widgets/` that wraps the `MaterialApp` builder or specific screens to show a top-anchored banner.
- **Rationale**: `connectivity_plus` is the most stable and maintained community package for this purpose.

## 3. Attendance Session Expiry Timer

**Objective**: Display a countdown banner when < 10 minutes remain in an active session.

**Findings**:
- `AttendanceSession` model has `endsAt` (DateTime).
- `AttendanceRepository` already has a periodic stream (15s) for some internal checks.
- **Decision**: Create a dedicated `AttendanceSessionTimerCubit` that:
    1. Receives the `endsAt` time.
    2. Uses a `Timer.periodic(Duration(seconds: 1))` to update the "seconds remaining".
    3. Emits state changes only when crossing the 10-minute threshold or every second if the banner is visible.
- **Rationale**: Keeps timer logic out of the main attendance BLoC to avoid unnecessary roster rebuilds every second.
- **Edge Case - System Clock**: We will rely on server-provided timestamps when the session is fetched, but local countdown will use the device clock. If the clock is significantly off, we might show "Expired" early/late. For P3, local clock reliance is acceptable.

## 4. Theme Token Deprecation

**Objective**: Guide developers to move away from legacy color aliases in `app_colors.dart`.

**Findings**:
- Many fields in `app_colors.dart` are duplicates of Material 3 tokens.
- **Decision**: Use `@Deprecated('Use [Replacement] instead')` on all identified legacy aliases.
- **Rationale**: Standard Dart way to communicate refactoring needs without breaking existing code.
