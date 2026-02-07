# Gemini Project Rules & Design System

This file serves as a reference for the design system, architecture, and coding standards of the `church_managment_system` project.

## 1. Design System Tokens

Tokens are centralized in `lib/core/theme/` and should always be used instead of hardcoded values.

### Colors (`app_colors.dart`)
- **Primary**: `AppColors.primary` (`#0F766E`) - Teal 700
- **Secondary**: `AppColors.secondary` (`#14B8A6`) - Teal 500
- **Background**: `AppColors.background` (`#F8FAFC`) - Slate 50
- **Surface**: `AppColors.surface` (`#FFFFFF`)
- **Text Primary**: `AppColors.textPrimary` (`#0F172A`) - Slate 900
- **Text Secondary**: `AppColors.textSecondary` (`#475569`) - Slate 600

### Spacing (`app_spacing.dart`)
- **Scale**: `xs: 4.0`, `sm: 8.0`, `md: 16.0`, `lg: 24.0`, `xl: 32.0`, `xxl: 48.0`
- **Helpers**: Use `AppSpacing.gapMd` (etc.) for spacing between widgets in Columns/Rows.

### Radius (`app_spacing.dart`)
- **Scale**: `sm: 8.0`, `md: 12.0`, `lg: 16.0`, `xl: 24.0`
- **Usage**: `AppRadius.mdRadius` for buttons/inputs, `AppRadius.lgRadius` for cards.

## 2. Typography

Configured via `GoogleFonts` in `lib/core/theme/app_typography.dart`.

- **Headlines (Merriweather)**: Use `Theme.of(context).textTheme.headlineLarge` etc.
- **Body (Source Sans 3)**: Use `Theme.of(context).textTheme.bodyMedium` etc.

## 3. Project Architecture

The codebase follows a **Feature-First Clean Architecture** pattern.

### Structure
- `lib/core/`: Global shared logic, theme, and generic widgets.
- `lib/features/`: Feature-specific modules divided into `data`, `domain`, and `presentation`.
- `presentation/`: Further divided into `bloc/`, `screens/`, and `widgets/`.

### Routing
- Uses standard `Navigator` with `onGenerateRoute`.
- Routes are defined in `lib/core/constants/routes.dart`.
- Router logic is in `lib/core/routing/app_router.dart`.

## 4. Coding Standards & Patterns

- **State Management**: Always use `flutter_bloc`.
- **Models**: Use `freezed` for immutable models and `json_serializable` for JSON handling.
- **UI Components**:
    - Prefer `StatelessWidget` for UI-only components.
    - Access theme values via `Theme.of(context)` or direct `AppColors`/`AppSpacing` constants.
    - Follow Material 3 principles.
- **Assets**: Reference assets from the `assets/` folder and ensure they are declared in `pubspec.yaml`.

## 5. Figma Integration Guidelines

When implementing Figma designs:
1. **Identify Tokens**: Match Figma colors and spacing to `AppColors` and `AppSpacing`.
2. **Use Shared Widgets**: Check `lib/core/widgets/` for existing generic widgets before creating new ones.
3. **Follow Feature Structure**: Place screen-specific widgets in `lib/features/<feature>/presentation/widgets/`.
4. **Theming**: Rely on the global `ThemeData` (especially for `InputDecoration` and `Button` styles) to ensure consistency.
