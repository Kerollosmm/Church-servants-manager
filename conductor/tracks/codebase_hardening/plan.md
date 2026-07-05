# Implementation Plan: codebase_hardening

## Phase 1: Dependency Cleanup
- [x] Task: Remove `google_generative_ai` dependency from `pubspec.yaml` and run `flutter pub get`.
- [x] Task: Conductor - User Manual Verification 'Dependency Cleanup' (Protocol in workflow.md).

## Phase 2: Attendance Feature Architecture Consolidation
- [x] Task: Relocate `lib/features/attendance/bloc/*` into `lib/features/attendance/presentation/bloc/`.
- [x] Task: Relocate `lib/features/attendance/screens/*` into `lib/features/attendance/presentation/screens/`.
- [x] Task: Update all import paths across `lib/` and verify with `flutter analyze`.
- [x] Task: Conductor - User Manual Verification 'Attendance Feature Consolidation' (Protocol in workflow.md).

## Phase 3: Design Token Refactoring (`attendance` & `results`)
- [x] Task: Audit and refactor hardcoded colors in `lib/features/attendance/presentation/` to `AppColors` tokens.
- [x] Task: Audit and refactor hardcoded colors in `lib/features/results/presentation/` to `AppColors` tokens.
- [x] Task: Verify zero raw color leaks with `flutter analyze`.
- [x] Task: Conductor - User Manual Verification 'Design Token Refactoring' (Protocol in workflow.md).

## Phase 4: Localization Setup & ARB String Extraction
- [x] Task: Setup `l10n.yaml`, `lib/l10n/app_en.arb`, and `lib/l10n/app_ar.arb`.
- [x] Task: Extract hardcoded UI strings into ARB resource files and wire up `AppLocalizations` in `MaterialApp`.
- [x] Task: Run final `flutter analyze` static verification.
- [x] Task: Conductor - User Manual Verification 'Localization Setup' (Protocol in workflow.md).
