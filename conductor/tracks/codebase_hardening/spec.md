# Track Specification: codebase_hardening

## Overview
- **Track Name**: `codebase_hardening`
- **Track Type**: Refactoring & Technical Debt Remediation
- **Goal**: Fix all Section B (Partially Implemented) and Section D (Out-of-Scope Code Found) findings identified during the `project-state-audit` gap analysis prior to starting new feature work.
- **Constraints**:
  - Zero new business features.
  - Zero changes to the offline sync engine, Firestore rules, or BLoC business logic.
  - Structural cleanup and code quality hardening only.
  - Run `flutter analyze` after every task and resolve all warnings.

## Scope & Requirements

### 1. Unused AI Dependency Removal
- Remove `google_generative_ai: ^0.4.7` from `pubspec.yaml`.
- Run `flutter pub get`.
- Confirm zero compilation or build errors across the project.

### 2. Attendance Feature Clean Architecture Consolidation
- Relocate legacy/top-level `lib/features/attendance/bloc/` into `lib/features/attendance/presentation/bloc/`.
- Relocate legacy/top-level `lib/features/attendance/screens/` into `lib/features/attendance/presentation/screens/`.
- Remove empty legacy folders.
- Update all internal and cross-feature import statements.
- Do NOT alter any BLoC or UI logic.
- Run `flutter analyze` and verify clean static analysis.

### 3. Design Tokens & Color Hardening (`attendance` & `results`)
- Audit presentation widgets in `lib/features/attendance/presentation/` and `lib/features/results/presentation/` for hardcoded `Color(...)` or `Colors.*` usage.
- Replace all raw colors with semantic design tokens defined in `lib/core/theme/app_colors.dart`.
- Add new color tokens to `AppColors` if required to support specific design states (e.g. attendance badge states).
- Run `flutter analyze`.

### 4. Internationalization (l10n) Infrastructure & Arabic Extraction
- Create `l10n.yaml` in project root configuring ARB source directory (`lib/l10n`) and synthetic code generation.
- Create `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.
- Extract all hardcoded Arabic strings from widgets in `lib/features/attendance/` and `lib/features/results/` into ARB resource keys.
- Configure `MaterialApp` in `lib/church_app.dart` / `lib/main.dart` with `AppLocalizations.delegate` and supported locales (`ar`, `en`).
- Run `flutter analyze`.

## Acceptance Criteria
- `pubspec.yaml` is clean without unused dependencies.
- `lib/features/attendance/` strictly follows feature-first Clean Architecture (`data/`, `domain/`, `presentation/`).
- Zero hardcoded colors in `attendance` and `results` presentation widgets.
- Infrastructure for `l10n` is active and all UI strings in `attendance` and `results` are extracted to ARB files.
- `flutter analyze` passes with 0 errors and 0 warnings.
