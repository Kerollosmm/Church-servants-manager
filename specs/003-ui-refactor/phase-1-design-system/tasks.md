# Phase 1 Tasks — Design System Foundation

## Prerequisites
- [x] Read `plan.md` in this folder
- [x] Read `DESIGN.md` for Ochre Sanctuary specs
- [x] Read `rules.md` for Flutter code quality rules

---

## Task 1.1 — Add `google_fonts` Dependency
- [x] Run: `flutter pub add google_fonts`
- [x] Verify `pubspec.yaml` shows `google_fonts: ^6.x.x`

## Task 1.2 — Update `app_colors.dart`
- [x] Replace all color definitions with Ochre Sanctuary palette
- [x] Add `primaryContainer`, `outline`, `shadow` constants
- [x] Add dartdoc comment to each constant explaining its semantic role
- [x] No pure `Colors.black` — use `Color(0xFF1C1C1E)`
- [x] Verify: `flutter analyze` → 0 errors in this file

## Task 1.3 — Update `app_typography.dart`
- [x] Import `google_fonts`
- [x] Define `buildTextTheme()` using `GoogleFonts.workSans()` for all roles
- [x] Add Arabic helper: `notoSansArabic(TextStyle base)` utility function
- [x] Set `height: 1.5` for body, `height: 1.4` for labels (WCAG line-height)
- [x] Verify: no lint warnings, all constructors `const` where possible

## Task 1.4 — Create `ochre_theme_extension.dart`
- [x] Create file at `lib/core/theme/ochre_theme_extension.dart`
- [x] Define `OchreTheme extends ThemeExtension<OchreTheme>`
- [x] Fields: `cardShadow`, `buttonShadow`, `blobOpacity`, `headerTint`
- [x] Implement `copyWith()` and `lerp()` correctly
- [x] Add static `light` factory with Ochre Sanctuary values
- [x] Add dartdoc to class and all public members

## Task 1.5 — Update `app_theme.dart`
- [x] Use `ColorScheme.fromSeed(seedColor: AppColors.primary)`
- [x] Register `OchreTheme.light` in `extensions` list
- [x] Configure `AppBarTheme`: `backgroundColor: AppColors.surface`, elevation 0
- [x] Configure `CardTheme`: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusCard))`
- [x] Configure `ElevatedButtonThemeData`: solid ochre + white text + `scale-0.98` via `overlayColor`
- [x] Configure `InputDecorationTheme`: `filled: true`, `fillColor: AppColors.surfaceContainerLow`, border `outline/20`
- [x] Verify: `flutter analyze` → 0 errors

## Task 1.6 — Update `app_spacing.dart`
- [x] Add all constants from plan: `paddingPage`, `radiusCard`, `radiusInput`, `iconSize`
- [x] Add `spacingXS=4`, `spacingS=8`, `spacingM=16`, `spacingL=24`, `spacingXL=32`
- [x] Verify: `flutter analyze` → 0 errors

## Task 1.7 — Create Atom Widgets

### `app_primary_button.dart`
- [x] `StatelessWidget`, takes `String label`, `VoidCallback? onPressed`, `bool isLoading`
- [x] Use `AnimatedScale` for `scale-0.98` on press via `GestureDetector` + `ValueNotifier`
- [x] Background: `AppColors.primary`, text: white, shadow from `OchreTheme.buttonShadow`
- [x] `const` constructor
- [x] Dartdoc comment

### `app_input_field.dart`
- [x] Wraps `TextFormField`
- [x] Props: `label`, `hint`, `leadingIcon`, `controller`, `validator`, `keyboardType`, `obscureText`
- [x] Applies `InputDecoration` from `InputDecorationTheme` automatically
- [x] RTL icon placement: `prefixIcon` in LTR → becomes `suffixIcon` for RTL via `Directionality`
- [x] Actually use `prefixIcon` always and rely on `Directionality` widget above for RTL mirroring

### `app_search_bar.dart`
- [x] Similar to input but `suffixIcon` is search icon, no label
- [x] Emits `onChanged(String value)` callback

### `app_avatar.dart`
- [x] Shows `CachedNetworkImage` if URL provided, else initials `CircleAvatar`
- [x] Radius parameter, border color: `AppColors.outline`

### `app_badge.dart`
- [x] Small pill widget: `label`, `color` (defaults to primary)
- [x] Used for present/absent/excused status indicators

## Task 1.8 — Create Molecule Widgets

### `app_person_list_tile.dart`
- [x] `AppAvatar` + name column + subtitle + optional trailing widget
- [x] Uses `ListTile` or custom `Row` — prefer `Row` for full Ochre control
- [x] `onTap` callback

### `app_section_card.dart`
- [x] Container with `AppSpacing.radiusCard` radius
- [x] Optional `headerTitle` shown in `primaryContainer` tinted strip
- [x] `child` widget
- [x] Shadow from `OchreTheme.cardShadow`

### `app_info_row.dart`
- [x] `Row` with `label` (12px, `onSurface`) and `value` (14px, `onBackground`)
- [x] `Divider` below, `primary/10` color
- [x] Used in profile detail screens

### `app_stat_card.dart`
- [x] Icon (20px, primary) + large number + small label
- [x] `AppSectionCard` wrapper
- [x] Used in dashboards

## Task 1.9 — Create Organism Widgets

### `app_header.dart`
- [x] Row: logo (`AppLogo`) + title + optional subtitle
- [x] Background: `AppColors.surface` with `primaryContainer` overlay (5%)
- [x] Ochre bottom-edge gradient accent (2px height `LinearGradient`)
- [x] Props: `title`, `subtitle?`, `showLogo: true`

### `app_screen_shell.dart`
- [x] `Scaffold` wrapper: `backgroundColor: AppColors.background`
- [x] Accepts: `appBar`, `body`, `floatingActionButton`
- [x] Adds decorative background blobs via `AppGradientDecoration` (positioned, blur 100, 20% opacity)

### `app_gradient_decoration.dart`
- [x] Two decorative `Positioned` `Container`s with `BoxDecoration(gradient: ..., borderRadius: ..., boxShadow: ...)`
- [x] `BackdropFilter` + `ImageFilter.blur(sigmaX: 100)` or simulated with opacity
- [x] `color: AppColors.primary.withOpacity(0.20)`

### `app_empty_state.dart` (update existing)
- [x] Ensure icon is `AppColors.primary`, message uses `bodyMedium` theme text style
- [x] Optional `actionLabel` button

## Task 1.10 — Verify Logo Asset
- [x] Check `pubspec.yaml` for `assets/images/logo_elkarooz.png`
- [x] If missing, add and run `flutter pub get`
- [x] Verify `AppLogo` widget in `lib/core/widgets/app_logo.dart` uses correct path

## Task 1.11 — Widget Tests for Atoms
- [x] `test/core/widgets/app_primary_button_test.dart`
  - asserts button renders label, invokes `onPressed`, shows loader when `isLoading: true`
- [x] `test/core/widgets/app_input_field_test.dart`
  - asserts validator fires, leading icon renders
- [x] Run: `flutter test test/core/`

## Task 1.12 — Final Verification
- [x] `flutter analyze` → 0 errors, 0 warnings
- [x] `flutter test` → all tests pass
- [ ] Build debug APK: `flutter build apk --debug` → compiles without error
