# Admin Dashboard UI Refactor Plan

## 1. Background & Motivation
The current `AdminDashboardScreen` is a basic, static list of navigation tiles. To align with the new "Ochre Sanctuary" design system and the provided HTML mockup, we need a complete UI overhaul. The new dashboard must be rich, interactive, and modular, featuring KPI metrics, quick actions, and recent activity logs. Furthermore, the UI must remain highly performant (60fps) avoiding raster thread jank caused by improper use of blurs and shadows, and must adhere to the offline-first Clean Architecture of the project.

## 2. Scope & Impact
- **Target Screen:** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
- **New Components:** KPI Cards, Quick Action Buttons, Activity List Items (to be created in `lib/features/admin/presentation/widgets/`).
- **State Management:** Introduction of `AdminDashboardBloc` to handle dynamic data fetching.
- **Theming:** Updating `app_colors.dart` and `app_theme.dart` to enforce the Ochre Sanctuary palette (`#a58255`, `#f7f7f6`).

## 3. Proposed Solution (Approach A)
We will implement the "Full Slivers & BLoC Overhaul" approach:
1. **CustomScrollView & Slivers:** Replace the `ListView` with a `CustomScrollView` containing `SliverAppBar` (for the logo header), `SliverToBoxAdapter` (welcome & quick actions), `SliverGrid` (KPIs), and `SliverList` (Recent Activity). This ensures optimal scroll performance by avoiding `shrinkWrap`.
2. **Ochre Sanctuary Design:** Apply the "No-Line" rule using background tints (`primary/5`) for card separation instead of borders. Implement the dual-font typographic hierarchy.
3. **Performance Optimizations:** 
   - Avoid expensive `BackdropFilter` or `ImageFilter.blur` over large areas. Use soft `RadialGradient` decorations to simulate atmospheric blurs, or encapsulate minimal blurs within a `RepaintBoundary`.
   - Aggressively use `const` constructors for static layout elements.
4. **BLoC & Offline-First:** Build `AdminDashboardBloc` to manage state (`Loading`, `Loaded`, `Error`). It will fetch cached data from Hive first (for instant UI rendering) before syncing with Firestore.

## 4. Implementation Plan

### Phase 1: Theme & Assets Preparation
- Update `lib/core/theme/app_colors.dart` to include specific Ochre Sanctuary colors (`primary`, `backgroundLight`, `backgroundDark`).
- Ensure typography (`Noto Sans Arabic` & `Work Sans`) is correctly configured in `app_typography.dart`.
- Verify `logo_elkarooz.png` is accessible.

### Phase 2: Reusable Widgets Construction
- **KpiCard:** A modular card accepting icon, title, value, and trend percentage.
- **QuickActionCard:** Interactive button with distinct active states (`ScaleTransition`), using primary tints.
- **ActivityListItem:** Row component for recent activity logs, displaying icon, title, user, and time.

### Phase 3: BLoC Integration
- Create `AdminDashboardBloc`, `AdminDashboardEvent`, and `AdminDashboardState`.
- Implement data fetching logic (mocked initially, then connected to repositories for Hive/Firestore).

### Phase 4: Screen Assembly
- Rewrite `AdminDashboardScreen.dart` using a `Scaffold` and `CustomScrollView`.
- Assemble the sliver components: `AdminWelcomeSection`, `AdminKpiGrid`, `AdminQuickActions`, and `AdminRecentActivity`.

## 5. Verification
- **Visual:** Compare the Flutter output against the HTML mockup, ensuring RTL alignment, padding, and token accuracy.
- **Performance:** Run the app in `--profile` mode and use DevTools to verify that the raster thread maintains <16ms per frame during scrolling.
- **Architecture:** Ensure the BLoC correctly handles loading and loaded states without freezing the UI.