# Implementation Plan: codebase_hardening

## Phase 1: Dependency Cleanup
- [ ] Task: Remove `google_generative_ai` dependency from `pubspec.yaml` and run `flutter pub get`.
- [ ] Task: Conductor - User Manual Verification 'Dependency Cleanup' (Protocol in workflow.md).

## Phase 2: Attendance Feature Architecture Consolidation
- [ ] Task: Relocate `lib/features/attendance/bloc/*` into `lib/features/attendance/presentation/bloc/`.
- [ ] Task: Relocate `lib/features/attendance/screens/*` into `lib/features/attendance/presentation/screens/`.
- [ ] Task: Update all import paths across `lib/` and verify with `flutter analyze`.
- [ ] Task: Conductor - User Manual Verification 'Attendance Feature Consolidation' (Protocol in workflow.md).

## Phase 3: Design Token Refactoring (`attendance` & `results`)
- [ ] Task: Audit and refactor hardcoded colors in `lib/features/attendance/presentation/` to `AppColors` tokens.
- [ ] Task: Audit and refactor hardcoded colors in `lib/features/results/presentation/` to `AppColors` tokens.
- [ ] Task: Verify zero raw color leaks with `flutter analyze`.
- [ ] Task: Conductor - User Manual Verification 'Design Token Refactoring' (Protocol in workflow.md).

## Phase 4: Localization Setup & ARB String Extraction
- [ ] Task: Setup `l10n.yaml`, `lib/l10n/app_en.arb`, and `lib/l10n/app_ar.arb`.
- [ ] Task: Extract hardcoded UI strings into ARB resource files and wire up `AppLocalizations` in `MaterialApp`.
- [ ] Task: Run final `flutter analyze` static verification.
- [ ] Task: Conductor - User Manual Verification 'Localization Setup' (Protocol in workflow.md).
