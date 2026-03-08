# Action Plan - Church Management System

## Phase 1: Critical (Do First)
**ROI: High | Effort: Medium**

### 1.1 Add Test Coverage
- [x] **F-001**: Create baseline test directory structure
- [x] Add core auth/student/servant/team regression tests
- [x] Add validators coverage and provisioning service tests
- [ ] Add repository-focused tests for student/servant/team edge cases
- [ ] Add widget tests for form and management screens
- [ ] Run `flutter test` to verify tests pass
- **Estimated Time**: 4-6 hours

---

## Phase 2: High Priority
**ROI: High | Effort: Low-Medium**

### 2.1 Fix Discontinued Packages
- [ ] **F-002**: Remove build_resolvers
  - Edit pubspec.yaml, remove or replace
  - Run `flutter pub get`
- [ ] **F-003**: Update dependency tree for build_runner_core
  - Run `flutter pub upgrade`
  - Test build still works: `flutter build apk`

### 2.2 Upgrade Code Generation Packages
- [ ] **F-004**: Upgrade freezed to 3.x
  - Run `flutter pub upgrade freezed`
  - Regenerate models: `dart run build_runner build`
- [ ] **F-010**: Upgrade other dev dependencies
  - `flutter pub upgrade --major-versions`
  - Verify with `flutter pub outdated`

---

## Phase 3: Medium Priority
**ROI: Medium | Effort: Medium**

### 3.1 Fix Debug Logging
- [ ] **F-005**: Review and fix debugPrint statements
- [ ] Wrap all debugPrint in `if (kDebugMode)` blocks
- [ ] Remove any statements logging PII
- [ ] Files to review:
  - lib/features/student/presentation/bloc/student_data/student_data_bloc.dart
  - lib/features/team/presentation/bloc/team_cubit.dart
  - lib/core/utils/data_seeder.dart
- **Estimated Time**: 1-2 hours

### 3.2 Performance Improvements
- [ ] **F-007**: Reduce setState usage
  - [x] Convert student/team helper flows to controller/cubit-driven state where already refactored
  - [x] Convert team_members_screen.dart loading to Cubit
  - [ ] Continue reducing local form state in remaining heavy screens
  - Consider form_bloc package for complex forms
- [ ] **F-008**: Extract large widgets
  - [x] Split major student/servant form sections into clearer helpers/controllers
  - [ ] Continue extracting reusable widget components where screen builds remain large
  - Add const where possible
- **Estimated Time**: 3-4 hours

### 3.3 Code Formatting
- [ ] **F-006**: Run code formatter
  - `dart format lib/`
  - Add to CI pipeline
- **Estimated Time**: 10 minutes

---

## Phase 4: Low Priority (Nice to Have)
**ROI: Low | Effort: Low**

### 4.1 Error Handling
- [ ] **F-011**: Add error boundary
  - Wrap app with error handling widget
  - Add graceful error screens

### 4.2 Security Hardening
- [ ] **F-013**: Consider secure storage
  - Evaluate if sensitive data needs encryption
  - Migrate to flutter_secure_storage if needed

### 4.3 Accessibility
- [ ] Add semantic labels to key widgets
- [ ] Test with screen readers
- [ ] Add accessibility testing to CI

---

## Verification Checklist

After completing each phase:

### Phase 1 Verification
```bash
flutter test
# Should show passing tests
```

### Phase 2 Verification
```bash
flutter pub outdated
# Should show no outdated or discontinued packages
flutter build apk --debug
# Should complete without errors
```

### Phase 3 Verification
```bash
dart format --set-exit-if-changed lib/
# Should exit with code 0 (no changes)
flutter analyze
# Should show no issues
```

### Phase 4 Verification
```bash
flutter test --coverage
# Should show coverage percentage
```

---

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | Test Coverage | 4-6 hours |
| Phase 2 | Package Updates | 2-3 hours |
| Phase 3 | Logging & Performance | 4-6 hours |
| Phase 4 | Error Handling & Security | 2-3 hours |
| **Total** | | **12-18 hours** |

---

## Notes

- Priority order is based on **risk reduction** and **maintainability impact**
- Test coverage is marked CRITICAL because without it, future changes risk breaking production
- Package updates should be done carefully with thorough testing after each change
- Consider creating a feature branch for these changes and merging via PR
