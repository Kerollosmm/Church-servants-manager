# Servant UI Refactor Plan: Ochre Sanctuary

## Objective
Refactor the Flutter Servant UI to implement the "Ochre Sanctuary" design system across the Dashboard, Servant List, Servant Profile, and Add/Edit Servant screens, while maintaining optimal Dart/Flutter performance and offline-first architecture.

## Background & Motivation
The application is adopting a new creative direction, "The Modern Sanctuary," which uses a grounded, earthy palette (centered around `#a58255`), sophisticated bilingual typography (Work Sans + Noto Sans Arabic), and soft-depth layering. This refactor will modernize the UI, improve usability, and maintain strict performance budgets (60fps) by substituting expensive runtime blurs with performant radial gradients.

## Scope & Impact
**Impacted Screens:**
- `lib/features/servant/presentation/screens/servant_dashboard_screen.dart`
- `lib/features/servant/presentation/screens/servant_list_screen.dart`
- `lib/features/servant/presentation/screens/servant_detail_screen.dart`
- `lib/features/servant/presentation/screens/add_edit_servant_screen.dart`

**Impacted Core UI:**
- New theme files in `lib/core/theme/`
- New reusable widgets in `lib/core/widgets/`

**Out of Scope:**
- Changes to `ServantBloc` or `SyncService` business logic.

## Proposed Solution

### 1. Design Tokens & Theme Foundation (`lib/core/theme/`)
- **Colors:** Integrate `primary` (`#a58255`), `background` (`#f7f7f6`), and `surface` (`#ffffff`).
- **Typography:** Configure `TextTheme` using `GoogleFonts.workSans` with a fallback to `GoogleFonts.notoSansArabic`. Standardize sizes (Display: 24px, Body: 14px, Labels: 12px).

### 2. Core Reusable Components (`lib/core/widgets/`)
- **`OchreButton`:** A primary button featuring a `primary/30` tinted `shadow-lg` and a custom `GestureDetector` that scales the button to 0.98 on press for tactile feedback.
- **`OchreTextField`:** A `TextFormField` wrapper with `#f7f7f6` fill, `primary/20` border, `rounded-xl`, and proper RTL icon alignment.
- **`OchreCard`:** A container standardizing the "card-on-canvas" look with `rounded-xl` (12px), a subtle `primary/10` border, and `shadow-xl`.
- **`SanctuaryBackground`:** A reusable Scaffold wrapper that implements the atmospheric backgrounds. As agreed, we will use performant `RadialGradient` shapes with low opacity instead of the highly expensive `ImageFilter.blur`.

### 3. Screen Transformations
- **Dashboard Screen:** Implement the hero image card with gradient overlays, quick action metric cards, and the recent attendance list. Use `CachedNetworkImage` for student avatars.
- **Servant List Screen:** Build a sticky header with an integrated `OchreTextField` for search, an active/archived custom switch, and a highly performant `ListView.builder` for the servant cards.
- **Servant Profile Screen:** Implement the centered avatar with the primary active dot, action buttons row, and grid of informational `OchreCard`s.
- **Add/Edit Screen:** Segment the form into logical `OchreCard` blocks (Basic Info, Service Details, Extra Info). Keep the bottom sticky action bar responsive for mobile.

### 4. Performance & Architecture Guardrails
- **Raster Thread Optimization:** Strict avoidance of `Opacity` over complex trees, no `Clip.antiAliasWithSaveLayer`, and no runtime blurs. 
- **Dart Optimization:** Enforce `const` constructors on all static UI text, icons, and padding to short-circuit rebuilds.
- **BLoC Integration:** Wrap the new layouts in `BlocBuilder<ServantBloc, ServantState>` cleanly. No logic inside `build()` methods.
- **Image Caching:** All network images must use `cached_network_image` to support the offline-first requirement.

## Implementation Steps
1. **Foundation:** Update `app_colors.dart` and `app_typography.dart`.
2. **Components:** Build `OchreButton`, `OchreTextField`, `OchreCard`, and `SanctuaryBackground`.
3. **Screen 1:** Refactor `servant_dashboard_screen.dart`.
4. **Screen 2:** Refactor `servant_list_screen.dart`.
5. **Screen 3:** Refactor `servant_detail_screen.dart`.
6. **Screen 4:** Refactor `add_edit_servant_screen.dart`.
7. **Review & Test:** Verify pixel-perfect alignment against design specs and profile scrolling performance.