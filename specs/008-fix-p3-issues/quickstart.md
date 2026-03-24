# Quickstart: Fix P3 Backlog Issues

This guide covers how to verify and work with the P3 fixes.

## 1. Deprecation Warnings

Check `lib/core/theme/app_colors.dart`. You should see `@Deprecated` markers on legacy aliases.
Your IDE should strike through usages of `AppColors.textPrimary`, `AppColors.surfaceContainer`, etc.

## 2. Testing Pagination

To test Firestore pagination:
1. Ensure a team has more than 50 students.
2. Open the Student List.
3. Scroll to the bottom.
4. Verify that a loader appears briefly and more students are appended.

## 3. Testing Offline Indicator

To test the network indicator:
1. Disable WiFi/Data on your device or emulator.
2. An indicator "You are offline..." should appear at the top.
3. Re-enable network. The indicator should disappear.

## 4. Testing Session Expiry

To test the countdown:
1. Create a new attendance session with a duration of 11 minutes.
2. Open the attendance taking screen.
3. Wait 1 minute until the remaining time is < 10 minutes.
4. The "Session expires in..." banner should appear.
