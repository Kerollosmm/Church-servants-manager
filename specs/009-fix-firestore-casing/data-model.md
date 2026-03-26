# Data Model: Fix Firestore Collection Casing

## Overview

This feature does not introduce new business entities or schema fields. It corrects the canonical naming contract for existing Firestore collection paths and normalizes every direct usage of that contract.

## Entities

### 1. Firestore Collection Path Contract

- **Purpose**: Defines the approved collection names used by all application, backend, test, and configuration code when targeting Firestore.
- **Canonical values**:
  - `users`
  - `students`
  - `classes`
- **Validation rules**:
  - Values must be lowercase.
  - Values must match the security-rule collection paths exactly.
  - Values must remain identifier-compatible with existing callers by preserving current constant names.

### 2. Firestore Path Consumer

- **Purpose**: Any code artifact that references a Firestore collection path.
- **Examples in scope**:
  - Shared constants file
  - Repository and service collection lookups
  - Cloud Functions backend constants
  - Test fixtures and test Firestore setup
  - `firestore.indexes.json` collection group names
- **Validation rules**:
  - No consumer may retain `Users`, `Students`, or `Classes` as Firestore collection path literals.
  - Consumer updates must not rename public Dart identifiers.

## Relationships

- The **Firestore Collection Path Contract** is consumed by all **Firestore Path Consumers**.
- The same contract must align with Firestore security rules and index definitions.

## State Transitions

### Collection Path Contract State

1. **Current state**: Mixed casing (`Users`, `Students`, `Classes`) exists in constants and hardcoded literals.
2. **Target state**: All canonical Firestore path values are lowercase and consistent across code, tests, backend, and config.
3. **Invalid state**: Any remaining uppercase Firestore path literal after normalization.

## Acceptance Mapping

- **FR-001 to FR-003** map to the canonical lowercase values.
- **FR-004 to FR-006** map to preserving identifiers and limiting scope to string-value normalization.
- **FR-007** maps to exact alignment with protected lowercase paths.
- **FR-008** maps to validation across existing automated checks.
