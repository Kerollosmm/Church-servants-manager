# 003 — Full UI Refactor: Ochre Sanctuary Design System

## Goal
Refactor every screen in the Church Management System to match the Stitch-defined designs while
strictly following:
- **DESIGN.md** — Ochre Sanctuary design tokens, typography, elevation, component rules
- **rules.md** — Flutter/Dart best practices (SOLID, composition, immutability, `const`, etc.)
- **All Flutter skills in `.agent/skills/`** — mandatory reading before each implementation step

---

## Stitch Reference Screens (Project ID: 10639386997146535841)

| Screen | Stitch ID |
|---|---|
| Splash Screen (Restored) | `6fa54652fca14a8cb2e4d1da296b8328` |
| Login Screen with Logo | `1fe08fff9379424e80ddbd2b008b475b` |
| Admin Dashboard (Matched Header) | `8b55a3308238485ead6902d032d0c7d2` |
| Servant Dashboard with Logo | `d50e3bba02924f9d99309b1d20598e9a` |
| Student List | `2a49c37d0a754f7e9b30ebc79b5c2756` |
| Student Profile Details | `e094de19e0b84e498bc20a6358e8c35e` |
| Add/Edit Student | `0fc429b6cf234945bb0670dc362752f8` |
| Attendance History | `097a7bd7e2ba4197b78d04cf2aad1bda` |
| Create Attendance Session | `5cf6c91c4e2a4f389bd44c1f4596966b` |
| Attendance Taking | `5f7e0aa247de40e6abb4513ce806e99a` |
| Student Attendance History | `6101e677a7544d64baa5ea76c2b97bda` |
| Servant List | `369ea739c5fe49f294e7647b1d258b95` |
| Servant Profile Details | `16eff08817f8468da656204aa4b39c67` |
| Add/Edit Servant | `094981703451476e8e2f48aadd697881` |

---

## Ochre Sanctuary Design Tokens (from DESIGN.md)

```dart
// Palette
primary      = Color(0xFFa58255)  // Ochre — all brand actions
background   = Color(0xFFf7f7f6)  // Canvas
surface      = Color(0xFFFFFFFF)  // Cards / Primary surfaces
onBackground = Color(0xFF1C1C1E)  // Warm near-black (NOT pure #000)

// Typography: Work Sans (Latin) + Noto Sans Arabic (RTL)
// Display/H1: 24px Bold   — page titles
// Body:       14px Regular — content / forms  (line-height: 1.5)
// Label:      12px Regular — metadata, helper text (line-height: 1.4)
// Icons:      20px Material Symbols Outlined

// Elevation
// Cards:    shadow-xl  (broad diffuse, no harsh border)
// Buttons:  shadow-lg + primary/30 color-tinted glow

// Components
// Buttons:  solid #a58255 bg, white text, rounded-xl, scale-[0.98] on press
// Inputs:   surfaceContainerLow fill, 1px border primary/20, leading icon in primary
// Cards:    rounded-xl (12px), border primary/10
// RTL-first layout — EdgeInsetsDirectional, TextDirection.rtl
// Min border-radius: 8px (rounded-lg)
// Main content padding: 32px (p-8)
// No pure black — use Color(0xFF1C1C1E)
// No sharp corners — minimum rounded-lg
```

---

## 🔧 Mandatory Flutter Skills (from `.agent/skills/`)

> **RULE:** Before implementing any screen or component, read and apply the relevant Flutter
> skill. Open `.agent/skills/<skill-name>/SKILL.md` first — do NOT skip this step.

| Skill | When to Apply | Phases |
|---|---|---|
| `flutter-theming-apps` | Every screen — `ThemeData`, `OchreTheme` extension, `ColorScheme` | 1–5 |
| `flutter-building-layouts` | Every screen — constraint system, `CustomScrollView`, overflow safety | 1–5 |
| `flutter-architecting-apps` | Layered arch — Presentation / Domain / Data kept separate at all times | All |
| `flutter-building-forms` | Login, Add/Edit Student, Add/Edit Servant, Create Attendance Session | 2, 4, 5 |
| `flutter-managing-state` | Attendance toggle, filter chips, form submit state | 3, 4, 5 |
| `flutter-animating-apps` | Splash hero, status toggle animation, list entry transitions | 2, 5 |
| `flutter-testing-apps` | Widget tests for every refactored screen — use AAA pattern | 1–5 |
| `flutter-improving-accessibility` | Semantics on all interactive elements, WCAG 4.5:1 contrast | 1, 4, 5 |
| `flutter-caching-data` | `AppAvatar` with `cached_network_image` for photo URLs | 1 |

---

## Phases Overview

| Phase | Name | Scope | Folder |
|--|--|--|--|
| 1 | Design System Foundation | Theme tokens, shared atoms/molecules/organisms | `phase-1-design-system/` |
| 2 | Auth & Splash | Splash + Login screens | `phase-2-auth/` |
| 3 | Dashboards | Admin dashboard + Servant dashboard | `phase-3-dashboards/` |
| 4 | Student Feature | List, Profile, Add/Edit, Attendance history | `phase-4-students/` |
| 5 | Servant & Attendance | Servant screens + all Attendance screens | `phase-5-servant-attendance/` |

Each phase folder contains:
- `plan.md` — detailed design decisions, architecture, component breakdown, Stitch references
- `tasks.md` — checkbox task list to execute the plan step by step

---

## Cross-Phase Engineering Rules (from rules.md)

1. **SOLID & Composition** — prefer `StatelessWidget` composition; no "God" build methods
2. **Private Widgets** — extract `_MySection extends StatelessWidget` instead of `_buildSection()` methods
3. **`const` everywhere** — use `const` constructors in all `build()` calls to minimize rebuilds
4. **`ListView.builder`** — mandatory for all list screens; no `Column + map()` for lists
5. **`ThemeExtension`** — `OchreTheme` for custom tokens not in base `ColorScheme`
6. **`google_fonts`** — Work Sans + Noto Sans Arabic via `TextTheme`; no raw `TextStyle` font families
7. **RTL** — `Directionality(textDirection: TextDirection.rtl)` at screen root; `EdgeInsetsDirectional`
8. **No pure black** — always `Color(0xFF1C1C1E)` or theme `onBackground`
9. **No sharp corners** — minimum `BorderRadius.circular(8)` everywhere
10. **No literals** — colors via `AppColors.*`, spacing via `AppSpacing.*`, no magic numbers
11. **Accessibility** — `Semantics` labels on all icons/buttons, min 48×48 touch target
12. **Error handling** — all async operations have error states surfaced to UI via BLoC state

---

## File Structure Created by This Refactor

```
lib/
  core/
    theme/
      app_colors.dart                 ← MODIFY: Ochre palette constants
      app_typography.dart             ← MODIFY: Work Sans + Noto Sans Arabic
      app_theme.dart                  ← MODIFY: ThemeData with all ComponentThemes
      app_spacing.dart                ← MODIFY: paddingPage=32, radiusCard=12, etc.
      ochre_theme_extension.dart      ← NEW: ThemeExtension for cardShadow, buttonShadow
    widgets/
      atoms/                          ← NEW folder
        app_primary_button.dart
        app_text_button.dart
        app_input_field.dart
        app_search_bar.dart
        app_avatar.dart
        app_badge.dart
      molecules/                      ← NEW folder
        app_person_list_tile.dart
        app_section_card.dart
        app_info_row.dart
        app_stat_card.dart
      organisms/                      ← NEW folder
        app_header.dart
        app_screen_shell.dart
        app_gradient_decoration.dart

  features/
    auth/presentation/screens/
      splash_screen.dart              ← NEW/MODIFY
      login_screen.dart               ← MODIFY (decompose into private widgets)
    admin/presentation/screens/
      admin_dashboard_screen.dart     ← MODIFY
    servant/presentation/screens/
      servant_dashboard_screen.dart   ← MODIFY
      servant_list_screen.dart        ← MODIFY
      servant_detail_screen.dart      ← MODIFY
      add_edit_servant_screen.dart    ← MODIFY
    student/presentation/screens/
      student_home_screen.dart        ← MODIFY
      student_profile_screen.dart     ← MODIFY
      student_edit_screen.dart        ← MODIFY
      student_detail_screen.dart      ← MODIFY
    attendance/presentation/screens/
      attendance_history_screen.dart  ← MODIFY
      attendance_session_create_screen.dart ← MODIFY
      attendance_taking_screen.dart   ← MODIFY
      student_attendance_screen.dart  ← MODIFY
```

---

## Verification Strategy

### Automated (run after each phase)
```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

### Visual (per screen)
1. Build: `flutter run`
2. Compare side-by-side with Stitch screenshot URLs in each phase's `plan.md`
3. Verify RTL layout
4. Verify no `RenderFlex` overflow on 375px width

### Accessibility
- Test with Android TalkBack: all buttons announce correctly
- Verify contrast ≥ 4.5:1 for all text (use `flutter_accessibility_service` or manual check)
