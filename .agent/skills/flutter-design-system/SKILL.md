---
name: flutter-design-system
description: Guidelines for Visual Design, Theming, Colors, Fonts, and Assets in Flutter
license: Private
---

# Flutter Design System

## Visual Design Principles
* **Aesthetics:** Build beautiful, intuitive UIs.
* **Responsiveness:** Ensure adaptation to mobile and web using `LayoutBuilder` or `MediaQuery`.
* **Typography:** Use font sizes to emphasize hierarchy (hero text, section headlines).
* **Tactile Feel:** Apply subtle noise texture to backgrounds; use multi-layered drop shadows for depth.
* **Interactive Elements:** Buttons/sliders should have elegant shadows or "glow" effects.

## Theming (Material 3)
* **ThemeData:** Centralize styles in `ThemeData`.
* **Modes:** Support Light, Dark, and System modes. Toggle via `themeMode`.
* **ColorScheme:** Use `ColorScheme.fromSeed` to generate harmonious palettes.
* **Component Themes:** Customize specific components (e.g., `cardTheme`) in `ThemeData`.

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
  ),
)
```

## Advanced Styling
* **ThemeExtensions:** Use `ThemeExtension` for custom design tokens (custom colors, sizes) not covered by `ThemeData`.
* **WidgetState:** Use `WidgetStateProperty.resolveWith` for interactive states (pressed, hovered).

## Typography
* **Font Families:** Limit to 1-2 families. Use `google_fonts`.
* **Scale:** Define a clear type scale (`displayLarge` to `labelSmall`).
* **Readability:**
    * Line Height: 1.4x - 1.6x.
    * Line Length: 45-75 chars for body text.
    * Avoid all caps for long text.

## Color Best Practices
* **Contrast:** WCAG 2.1 (4.5:1 for normal text).
* **Hierarchy:** 60-30-10 Rule (60% Neutral, 30% Secondary, 10% Accent).
* **Complementary:** Use with caution, mainly for accents.

## Assets & Images
* **Management:** Declare in `pubspec.yaml`.
* **Local:** `Image.asset`.
* **Network:** `Image.network` (always use `loadingBuilder` and `errorBuilder`) or `cached_network_image`.
* **Icons:** Use `ImageIcon` for custom image providers.
