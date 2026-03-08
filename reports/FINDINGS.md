# Code Review Findings

## F-001: Test Coverage Still Needs Expansion
- **Severity**: CRITICAL
- **Category**: Testing
- **Evidence**:
  - `test/` exists and core auth/student/servant/team paths are covered.
  - Coverage is still incomplete for widget flows, repository edge cases, and emulator/rules scenarios.
- **Impact**: Main regressions are better protected, but some UI and integration risks remain under-tested.
- **Fix**: Expand repository, widget, and emulator-style tests for the remaining critical flows.
- **Verification**: Run `flutter test` after adding tests and keep new coverage aligned with refactors

## F-002: Discontinued Package - build_resolvers
- **Severity**: HIGH
- **Category**: Dependencies
- **Evidence**: pubspec.yaml line ~56-63, output of `flutter pub outdated` shows "discontinued"
- **Impact**: Package no longer maintained, potential security issues, may break with future Dart/Flutter versions
- **Fix**: Remove from dev_dependencies and migrate to maintained alternatives
- **Verification**: Run `flutter pub upgrade` and verify no build issues

## F-003: Discontinued Package - build_runner_core
- **Severity**: HIGH
- **Category**: Dependencies
- **Evidence**: pubspec.yaml transitive dependency marked discontinued
- **Impact**: Same as F-002
- **Fix**: Review dependency tree, update injectable_generator
- **Verification**: Run `flutter pub deps | grep discontinued`

## F-004: Outdated freezed Package
- **Severity**: HIGH
- **Category**: Dependencies
- **Evidence**: pubspec.yaml - freezed: 2.5.2, latest: 3.2.5
- **Impact**: Missing new features, potential bugs in older version
- **Fix**: Run `flutter pub upgrade freezed` and regenerate models
- **Verification**: `flutter pub outdated | grep freezed`

## F-005: Debug Logging with Potential PII
- **Severity**: MEDIUM
- **Category**: Security
- **Evidence**: 
  - `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart:83` - `debugPrint('StudentDataBloc: Stream error - $error')`
  - `lib/features/team/presentation/bloc/team_cubit.dart:31` - `debugPrint('TeamCubit: $contextLabel - $error')`
  - `lib/core/utils/data_seeder.dart:134,203,206,234,245,254,264,292,355` - Multiple debugPrint statements
- **Impact**: Sensitive user data may be logged in debug builds
- **Fix**: Wrap all debugPrint with `if (kDebugMode)` or use dedicated logging package
- **Verification**: Search for `debugPrint` after fix - should only appear in kDebugMode blocks

## F-006: Formatting Issues in 11 Files
- **Severity**: LOW
- **Category**: Code Style
- **Evidence**: `dart format --set-exit-if-changed lib/` changed 11 files
- **Impact**: Inconsistent code style, poor maintainability
- **Fix**: Run `dart format lib/` and commit formatted files
- **Verification**: `dart format --set-exit-if-changed lib/` should exit with 0

## F-007: Excessive setState Usage
- **Severity**: MEDIUM
- **Category**: Performance
- **Evidence**: 
  - `lib/features/student/presentation/screens/student_edit_screen.dart` - 12+ setState calls
  - `lib/features/team/presentation/screens/team_members_screen.dart` - 8 setState calls
  - `lib/features/servant/presentation/screens/add_edit_servant_screen.dart` - 5 setState calls
- **Impact**: Unnecessary widget rebuilds, potential performance issues with large forms
- **Fix**: Refactor to use BLoC/Cubit for form state management
- **Verification**: Profile app with DevTools after fix

## F-008: Large Widget Build Methods
- **Severity**: MEDIUM
- **Category**: Performance
- **Evidence**: 
  - `student_edit_screen.dart:301` - 301+ line build method
  - `student_profile_screen.dart` - Multiple 100+ line build methods
  - `servant_detail_screen.dart` - Large widget trees
- **Impact**: Difficult to maintain, longer rebuild times
- **Fix**: Extract widgets using `const` constructors, create separate widget classes
- **Verification**: Run `flutter analyze` - no issues expected

## F-009: No Const Correctness in Some Widgets
- **Severity**: LOW
- **Category**: Performance
- **Evidence**: Some widgets missing const where possible
- **Impact**: Minor - extra widget rebuilds
- **Fix**: Add const to widgets that don't change
- **Verification**: Review files after adding const

## F-010: Outdated Dev Dependencies
- **Severity**: MEDIUM
- **Category**: Dependencies
- **Evidence**: 
  - flutter_lints: 5.0.0 -> 6.0.0
  - build_runner: 2.4.13 -> 2.12.2
  - injectable_generator: 2.6.2 -> 2.12.1
  - json_serializable: 6.8.0 -> 6.13.0
- **Impact**: Missing lint improvements, code generation features
- **Fix**: Run `flutter pub upgrade --major-versions`
- **Verification**: `flutter pub outdated` shows all green

## F-011: No Error Boundary Implementation
- **Severity**: MEDIUM
- **Category**: Error Handling
- **Evidence**: No FlutterError widget or ErrorBoundary in app
- **Impact**: App crashes without graceful degradation
- **Fix**: Wrap app with ErrorWidget or use flutter_bloc error handling
- **Verification**: Trigger error in app - should show graceful message

## F-012: Firebase API Keys in Source Code
- **Severity**: LOW (Acceptable)
- **Category**: Security
- **Evidence**: `lib/firebase_options.dart:50,60,68` - Hardcoded API keys
- **Impact**: Keys visible in source (but this is normal for Firebase client apps)
- **Fix**: No fix needed - Firebase API keys are meant to be public
- **Verification**: Confirm via Firebase documentation

## F-013: No Secure Storage Implementation
- **Severity**: LOW
- **Category**: Security
- **Evidence**: No flutter_secure_storage usage, using plain Hive
- **Impact**: Cached data not encrypted at rest
- **Fix**: Consider migrating to flutter_secure_storage for sensitive data
- **Verification**: Check data stored locally
