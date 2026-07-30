# Ochre Sanctuary Design System (CSMS)

## 1. Overview & Creative North Star
**Creative North Star: "The Modern Sanctuary"**
Ochre Sanctuary is a unified design system crafted for the ChurchServers Management System (CSMS). It marries the warmth of traditional heritage with the precision of contemporary digital interfaces. The design rejects the coldness of standard SaaS "blue" in favor of a grounded, earthy palette centered around rich Ochre (`#A58255`). The system is institutional yet welcoming, utilizing intentional whitespace, soft-depth layering, and tonal separation to create a focused, meditative user experience.

---

## 2. Color Palette & Tonal Hierarchy

### Primary Roles
- **Primary Ochre**: `#A58255` — Core brand identity, primary CTA, active states, key focal points.
- **Primary Container**: `#F3EDE2` — Light tinted surfaces, active list item backgrounds, subtle selection states.
- **Secondary Sand**: `#8C7355` — Supporting controls, secondary icons, subtle badges.
- **Background / Canvas**: `#F7F7F6` — Warm stone canvas for all screens.
- **Surface**: `#FFFFFF` — Primary elevated cards, dialogs, bottom sheets.
- **Surface Container Low**: `#F1EFF0` — Recessed groupings, table headers, form field fills.

### Text & Neutral Tokens
- **Text Primary (On Surface)**: `#1E293B` (Slate-900) — Deep, warm neutral for high-contrast reading. Never `#000000`.
- **Text Secondary**: `#64748B` (Slate-500) — Metadata, field labels, timestamps.
- **Text Muted**: `#94A3B8` (Slate-400) — Placeholders, disabled text.

### Semantic Tones (Subdued & Grounded)
- **Success / Present**: `#2E7D32` (Deep Forest Green) / Fill: `#E8F5E9`
- **Warning / Pending**: `#D97706` (Warm Amber) / Fill: `#FEF3C7`
- **Error / Absent**: `#C62828` (Crimson Earth) / Fill: `#FFEBEE`
- **Info**: `#1565C0` (Deep Muted Blue) / Fill: `#E3F2FD`

### The "No-Line" Rule
Visual separation must prioritize **tonal shifts** over borders:
- Use `surfaceContainerLow` (`#F1EFF0`) against white `surface` to define sections.
- 1px borders are strictly limited to active input fields or subtle card outlines, and must use `primary` at `0.10` or `0.15` opacity.

---

## 3. Typography System

Bilingual typography balancing geometric clarity with elegant Arabic calligraphy.
- **English Font**: `Work Sans` / `Inter` / System Sans.
- **Arabic Font**: `Noto Sans Arabic` / `Cairo`.

### Scale & Hierarchy
| Token | Size (px / rem) | Weight | Line Height | Usage |
|-------|-----------------|--------|-------------|-------|
| `displayLarge` | 32px / 2.0rem | Bold (700) | 1.2 | Feature headers, hero titles |
| `titleLarge` | 24px / 1.5rem | SemiBold (600) | 1.3 | Page titles, dialog headers |
| `titleMedium` | 18px / 1.125rem | Medium (500) | 1.4 | Card headers, section titles |
| `bodyLarge` | 16px / 1.0rem | Regular (400) | 1.5 | Primary reading text, form input text |
| `bodyMedium` | 14px / 0.875rem | Regular (400) | 1.5 | Standard table content, list subtext |
| `labelLarge` | 14px / 0.875rem | Medium (500) | 1.4 | Button text, interactive controls |
| `labelSmall` | 12px / 0.75rem | Medium (500) | 1.3 | Badges, field labels, metadata |

---

## 4. Spacing, Layout & Elevation

### Spacing Grid (8pt System)
- `4px` (`xxs`) - Micro gaps, icon-text padding
- `8px` (`xs`) - Internal element spacing, tight lists
- `12px` (`sm`) - Card internal padding (dense)
- `16px` (`md`) - Standard card padding, form gap
- `24px` (`lg`) - Section spacing, screen horizontal padding
- `32px` (`xl`) - Screen vertical padding, sanctuary margins

### Elevation & Soft Depth
- **Level 0 (Flat/Canvas)**: `#F7F7F6` canvas.
- **Level 1 (Card/Container)**: `#FFFFFF` card with soft shadow `BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4))`.
- **Level 2 (Floating Action / Elevated CTA)**: `#A58255` surface with tinted shadow `BoxShadow(color: Color(0x33A58255), blurRadius: 12, offset: Offset(0, 4))`.
- **Level 3 (Modal / Bottom Sheet)**: `#FFFFFF` surface with `blurRadius: 24`, dim background `Color(0x66000000)`.

---

## 5. Component Specifications

### Buttons
- **Primary CTA**: Solid Ochre (`#A58255`), white text, `borderRadius: 12px`, height `48px`, elevation glow `shadow-primary/20`, tactile shrink on press (`scale: 0.98`).
- **Secondary Button**: Soft fill (`primaryContainer` `#F3EDE2`), Ochre text (`#A58255`), no border.
- **Text / Ghost Button**: Transparent background, Ochre text, `borderRadius: 8px`.

### Input Fields & Forms
- **Container**: `surfaceContainerLow` fill (`#F1EFF0`), `borderRadius: 12px`, border `primary/15` (1px).
- **Focus State**: Ochre border (`#A58255`, 1.5px), soft outer halo (`primary/10`, 4px).
- **RTL Alignment**: Leading icon on right for Arabic, label top-aligned or inline right.

### Cards & Lists
- **Standard Card**: White `#FFFFFF`, `borderRadius: 16px`, soft ambient shadow, no heavy borders.
- **Interactive List Tile**: Height `56px` or `64px`, rounded `12px`, hover/active tint `primary/5`.

---

## 6. Strict Design Laws & Absolute Bans

1. **No Pure Black (#000000) or Pure White Canvas**: Always use Slate-900 `#1E293B` for dark text and Warm Sand `#F7F7F6` for background canvas.
2. **No Colored Side-Stripe Borders**: Never use a 3px/4px `border-left` colored stripe on cards. Use full subtle borders, background tints, or leading icons/badges.
3. **No Gradient Text**: Never use gradient text clipping. Use weight and size for emphasis.
4. **No Heavy Hard Shadows**: Never use black drop-shadows with low blur radius (`blur: 2px`). Use wide diffused shadows (`blur: 16px-24px`, low opacity).
5. **No Em Dashes (`—`) in UI Copy**: Use commas, colons, semicolons, or parentheses.
6. **RTL-First Symmetry**: Icons indicating directional flow (arrows, chevrons, login) must automatically mirror in RTL contexts.

---

## 7. Flutter Architecture Code Mapping

The Flutter codebase maps these tokens in `lib/core/theme/`:
- **`AppColors`**: `lib/core/theme/app_colors.dart`
- **`AppColorScheme`**: `lib/core/theme/app_color_scheme.dart`
- **`AppTypography`**: `lib/core/theme/app_typography.dart`
- **`AppSpacing`**: `lib/core/theme/app_spacing.dart`
- **`AppComponentThemes`**: `lib/core/theme/app_component_themes.dart`
- **`AppTheme`**: `lib/core/theme/app_theme.dart`