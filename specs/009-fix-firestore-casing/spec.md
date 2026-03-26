# Feature Specification: Fix Firestore Collection Casing

**Feature Branch**: `009-fix-firestore-casing`  
**Created**: 2026-03-24  
**Status**: Draft  
**Input**: User description: "Fix Firestore collection name casing mismatch in Church Attendance Flutter app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Restore authorized data access (Priority: P1)

As a servant or student, I need the app to read and write data using the correct collection names so that authorized screens work with the protected data they are supposed to access.

**Why this priority**: Incorrect collection naming breaks protected data access and prevents the app from working correctly under the defined access rules.

**Independent Test**: Can be fully tested by verifying that the canonical collection names used by the app match the protected data paths and that authorized users can complete their normal data flows without collection-path mismatches.

**Acceptance Scenarios**:

1. **Given** the app accesses user records, **When** it resolves the user collection name, **Then** it uses `users`.
2. **Given** the app accesses student records, **When** it resolves the student collection name, **Then** it uses `students`.
3. **Given** the app accesses team records, **When** it resolves the class/team collection name, **Then** it uses `classes`.

---

### User Story 2 - Preserve existing feature behavior (Priority: P2)

As a product owner, I need this correction to be narrowly scoped so that existing student, attendance, and team flows continue to behave the same apart from using the correct collection names.

**Why this priority**: The issue is a production stability defect, so the correction must not introduce unrelated behavior changes.

**Independent Test**: Can be fully tested by confirming that existing flows still compile and existing automated checks for BLoC and repository behavior continue to pass after the naming correction.

**Acceptance Scenarios**:

1. **Given** the collection naming correction is applied, **When** the application is built and validated, **Then** no callers fail because of renamed Dart identifiers.
2. **Given** the correction is applied, **When** existing automated checks are run, **Then** previously covered BLoC and repository behavior remains green.

---

### User Story 3 - Keep scope controlled (Priority: P3)

As a maintainer, I need the fix to change only the collection name values so that the codebase remains easy to review and low risk to release.

**Why this priority**: A constrained change reduces regression risk and speeds up verification for a production bug fix.

**Independent Test**: Can be fully tested by reviewing the changed collection definitions and confirming that only the canonical values changed while the public constant names remained the same.

**Acceptance Scenarios**:

1. **Given** the correction is complete, **When** the constants are reviewed, **Then** the Dart class name and constant variable names are unchanged.
2. **Given** the correction is complete, **When** the constant values are reviewed, **Then** only the three collection name values differ from the prior state.

---

### Edge Cases

- What happens if another file depends on the existing Dart constant names? The fix must preserve the existing class and constant identifiers so those references continue to work unchanged.
- What happens if some screens still use hard-coded uppercase collection names? The fix is not complete until all referenced collection access remains consistent with the canonical lowercase paths.
- What happens if automated checks reveal unrelated failures? The feature is considered blocked for release readiness until failures are triaged and the collection-casing change is shown not to have introduced breakage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define the canonical user collection name as `users`.
- **FR-002**: The system MUST define the canonical student collection name as `students`.
- **FR-003**: The system MUST define the canonical class/team collection name as `classes`.
- **FR-004**: The system MUST preserve the existing Dart class name and constant variable names while correcting the collection name values.
- **FR-005**: The system MUST ensure all existing references to these collection constants continue to compile without requiring caller-side renaming.
- **FR-006**: The system MUST keep the change scoped to correcting collection name values and MUST NOT alter unrelated business behavior.
- **FR-007**: The system MUST remain compatible with the existing protected data-access rules that expect lowercase collection paths.
- **FR-008**: The system MUST demonstrate that the current automated checks covering BLoC and repository behavior still pass after the correction.

### Key Entities *(include if feature involves data)*

- **Collection Name Constant**: The canonical application-defined name used whenever the app targets a protected data collection.
- **Protected Data Path**: The approved lowercase path used by the system's access controls to evaluate whether reads and writes are allowed.
- **Calling Module**: Any existing app module that references the shared collection name constants and must continue to function without identifier changes.

## Assumptions

- The production and non-production data stores use lowercase collection names as the authoritative naming standard.
- Existing callers already reference the shared collection constants rather than duplicating uppercase names in a way that changes this feature's scope.
- Validation for this feature includes compile verification and the existing automated checks most directly covering BLoC and repository behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of canonical collection name definitions for users, students, and classes match the approved lowercase names.
- **SC-002**: 0 existing callers require identifier renaming to adopt this fix.
- **SC-003**: 100% of validation checks selected for this fix complete without errors attributable to collection-path casing mismatch.
- **SC-004**: Reviewers can confirm in one diff that the change is limited to the intended collection name values with no unrelated behavior changes.
