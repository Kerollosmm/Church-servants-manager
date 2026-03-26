# Phase 1 - Foundation (Theme + Shared UI)

## Goal
Stabilize the design system so all upcoming screens are implemented using one consistent visual language.

## Scope
- `lib/core/theme/*`
- `lib/core/widgets/atoms/*`
- `lib/core/widgets/molecules/*`
- `lib/core/widgets/organisms/*`

## UI Inputs
- `UI Screens/ochre_sanctuary` (tokens and style direction)

## Plan
1. Align `AppColors`, typography, spacing, and component themes to the design reference.
2. Confirm reusable base widgets exist and remove duplication across features.
3. Normalize common shells: header, section cards, list tiles, input styles.
4. Add accessibility defaults: min tap size, semantic labels for icon actions.
5. Freeze foundation before phase 2.

## Refactor Constraints
- No feature screen should hardcode color, font size, or radii.
- Keep new shared widgets generic and reusable.
- Avoid adding feature logic to core widgets.

## Verification
- `flutter analyze`
- `flutter test test/core`
