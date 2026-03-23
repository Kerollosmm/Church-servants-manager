# Phase 1 — Design System Foundation

## Goal
Establish the complete Ochre Sanctuary token system and reusable shared widget library that all
subsequent phases will consume. Nothing screen-specific is built here — only the layer below all
screens.

---

## Stitch References (Design System)
- **logo_elkarooz.png** — asset already in project; confirm path in `pubspec.yaml`
- **Design System screen** — `asset-stub-assets-d8f4d3afa2d84c2b8a209b7d10b1734f-1773873081109`
  - Color palette swatches, typography scale, component spec

---

## Ochre Sanctuary Token Map

| Token | Value | Usage |
|---|---|---|
| `primary` | `#a58255` | Buttons, icons, active indicators |
| `background` | `#f7f7f6` | App canvas, scaffold bg |
| `surface` | `#ffffff` | Cards |
| `surfaceContainerLow` | `#f7f7f6` | Input fills |
| `onBackground` | `#1C1C1E` | Primary text |
| `onSurface` | `#3D3D3D` | Secondary text |
| `primaryContainer` | `#a58255/10` | Header tint backgrounds |
| `outline` | `#a58255/20` | Input borders |

---

## Implementation Plan

### 1.1 Update `app_colors.dart`
**File:** `lib/core/theme/app_colors.dart`

Replace existing placeholders with Ochre Sanctuary values:
```dart
static const Color primary = Color(0xFFa58255);
static const Color background = Color(0xFFf7f7f6);
static const Color surface = Color(0xFFFFFFFF);
static const Color surfaceContainerLow = Color(0xFFf7f7f6);
static const Color onBackground = Color(0xFF1C1C1E);
static const Color onSurface = Color(0xFF3D3D3D);
static const Color onPrimary = Color(0xFFFFFFFF);
static const Color primaryContainer = Color(0x1Aa58255); // 10% opacity
static const Color outline = Color(0x33a58255);          // 20% opacity
static const Color shadow = Color(0x4Da58255);           // 30% opacity for button glow
```

### 1.2 Create `ochre_theme_extension.dart` [NEW]
**File:** `lib/core/theme/ochre_theme_extension.dart`

```dart
@immutable
class OchreTheme extends ThemeExtension<OchreTheme> {
  const OchreTheme({
    required this.cardShadow,
    required this.buttonShadow,
    required this.blobOpacity,
    required this.headerTint,
  });

  final List<BoxShadow> cardShadow;    // shadow-xl equivalent
  final List<BoxShadow> buttonShadow;  // shadow-lg + primaryGlow
  final double blobOpacity;            // 0.20
  final Color headerTint;              // primary/5

  @override
  OchreTheme copyWith({...}) => ...;

  @override
  OchreTheme lerp(OchreTheme? other, double t) => ...;
}
```

### 1.3 Update `app_typography.dart`
**File:** `lib/core/theme/app_typography.dart`

Add `google_fonts` dependency (Work Sans + Noto Sans Arabic):
```dart
// pubspec.yaml: google_fonts: ^6.2.1
TextTheme buildTextTheme() => TextTheme(
  displayLarge: GoogleFonts.workSans(fontSize: 24, fontWeight: FontWeight.bold),
  bodyMedium:   GoogleFonts.workSans(fontSize: 14, height: 1.5),
  labelSmall:   GoogleFonts.workSans(fontSize: 12, color: AppColors.onSurface),
);
// Arabic override applied at screen level via DefaultTextStyle + NotoSansArabic
```

### 1.4 Update `app_theme.dart`
**File:** `lib/core/theme/app_theme.dart`

Wire `ColorScheme.fromSeed()` with `seedColor: AppColors.primary`, inject `OchreTheme`
extension, configure `appBarTheme`, `cardTheme`, `elevatedButtonTheme`, `inputDecorationTheme`.

### 1.5 Update `app_spacing.dart`
**File:** `lib/core/theme/app_spacing.dart`

Ensure p-8 (32px) standard + card radius xl (12px) constants exist:
```dart
static const double paddingPage = 32.0;   // p-8
static const double radiusCard = 12.0;    // rounded-xl
static const double radiusInput = 8.0;    // rounded-lg
static const double iconSize = 20.0;      // Material Symbols standard
```

### 1.6 Build Atomic Widget Library [NEW]

#### `lib/core/widgets/atoms/`
| Widget | Purpose |
|---|---|
| `app_primary_button.dart` | Solid ochre bg, white text, glow shadow, scale-0.98 active |
| `app_text_button.dart` | Ochre text, no fill |
| `app_input_field.dart` | surfaceContainerLow fill, 1px outline, leading icon |
| `app_search_bar.dart` | RTL-aware search field |
| `app_avatar.dart` | Circular avatar with fallback initials |
| `app_badge.dart` | Small chip for status (present/absent) |

#### `lib/core/widgets/molecules/`
| Widget | Purpose |
|---|---|
| `app_person_list_tile.dart` | Avatar + name + subtitle + trailing action |
| `app_section_card.dart` | rounded-xl card with optional header tint |
| `app_info_row.dart` | Label + value row for profile detail pages |
| `app_stat_card.dart` | Dashboard stat card with icon + number + label |

#### `lib/core/widgets/organisms/`
| Widget | Purpose |
|---|---|
| `app_header.dart` | Branded header: logo + title + optional subtitle |
| `app_screen_shell.dart` | Scaffold wrapper: bg color, padding, optional back btn |
| `app_empty_state.dart` | Centered icon + message for empty lists |
| `app_gradient_decoration.dart` | Background blob Positioned decorations |

### 1.7 Confirm Logo Asset
Verify `assets/images/logo_elkarooz.png` is declared in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/logo_elkarooz.png
```

---

## Inter-Phase Dependencies
- All phases 2-5 **import** atoms, molecules, and organisms from this phase
- `OchreTheme` extension is accessed via `Theme.of(context).extension<OchreTheme>()!`
- No screen file may define colors as literals — must use `AppColors.*`

---

## Affected Files
| Action | File |
|---|---|
| MODIFY | `lib/core/theme/app_colors.dart` |
| MODIFY | `lib/core/theme/app_typography.dart` |
| MODIFY | `lib/core/theme/app_theme.dart` |
| MODIFY | `lib/core/theme/app_spacing.dart` |
| NEW | `lib/core/theme/ochre_theme_extension.dart` |
| NEW | `lib/core/widgets/atoms/app_primary_button.dart` |
| NEW | `lib/core/widgets/atoms/app_text_button.dart` |
| NEW | `lib/core/widgets/atoms/app_input_field.dart` |
| NEW | `lib/core/widgets/atoms/app_search_bar.dart` |
| NEW | `lib/core/widgets/atoms/app_avatar.dart` |
| NEW | `lib/core/widgets/atoms/app_badge.dart` |
| NEW | `lib/core/widgets/molecules/app_person_list_tile.dart` |
| NEW | `lib/core/widgets/molecules/app_section_card.dart` |
| NEW | `lib/core/widgets/molecules/app_info_row.dart` |
| NEW | `lib/core/widgets/molecules/app_stat_card.dart` |
| NEW | `lib/core/widgets/organisms/app_header.dart` |
| NEW | `lib/core/widgets/organisms/app_screen_shell.dart` |
| NEW | `lib/core/widgets/organisms/app_gradient_decoration.dart` |
| MODIFY | `lib/core/widgets/app_empty_state.dart` |
| VERIFY | `pubspec.yaml` (google_fonts dep + asset path) |
