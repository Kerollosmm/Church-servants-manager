# Track Specification: project_state_audit

## Overview
- **Track Name**: `project_state_audit`
- **Track Type**: Read-Only Audit & Gap Analysis
- **Goal**: Perform a full code-archaeologist gap analysis between what is documented in `conductor/product.md`, `conductor/tech-stack.md`, `conductor/product-guidelines.md`, and what actually exists in the current `lib/` codebase and project root.
- **Constraint**: Act strictly as a code-archaeologist. Do NOT write, modify, or refactor any production application code in this track.

## Scope & Requirements

### 1. Feature-First Clean Architecture Audit (`lib/`)
Scan the entire `lib/` directory structure and compare it against the Phase 1 Clean Architecture specification (feature-first: domain/data/presentation per feature).
For each feature folder found (`auth`, `servants`, `students`, `attendance`, `results`, etc.), report:
- Does `domain/` exist with entities, use cases, repository interfaces?
- Does `data/` exist with models (DTOs), datasources (local Hive + remote Firestore), repository implementations?
- Does `presentation/` exist with BLoC (events/states/bloc), pages, widgets?
- Is it fully implemented, partially stubbed, or missing entirely?

### 2. Spark Plan Constraints Audit (No Cloud Functions)
Check for Cloud Functions references anywhere in the codebase:
- `functions/` root directory or subdirectories
- `cloud_functions` package import in any Dart file
- Any callable function calls (e.g. `FirebaseFunctions.instance.httpsCallable`)
- Flag any occurrences as strict violations of the Spark Plan constraint and list exact file locations and line numbers.

### 3. Legacy Code Audit (Two-App Remnants)
Check for any leftover code or configuration from the old two-app system (separate attendance app + separate results app) that should be removed per the unified-app decision.

### 4. Tech Stack & Dependencies Audit (`pubspec.yaml`)
Compare `pubspec.yaml` against `conductor/tech-stack.md`:
- Check for required dependencies: `get_it`, `injectable`, `dartz`, `uuid`, `workmanager`, `connectivity_plus`, `flutter_secure_storage`, `hive`, `hive_flutter`, `flutter_bloc`, `equatable`.
- Flag any dependency mismatches, missing required packages, or unused/legacy packages.

### 5. Security & RBAC Audit (Firestore Rules)
Check for any Firestore Security Rules file (`firestore.rules` or similar):
- Confirm whether Firestore-first RBAC (role checked via `get()` on `/users/{userId}`) is implemented in rules.
- Flag whether security relies on Custom Claims or assumed Cloud Function triggers.

### 6. UI & Code Quality Guidelines Compliance
Identify any:
- Hardcoded strings
- Hardcoded colors
- Business logic inside UI widgets
- Flag as violations of `conductor/product-guidelines.md`.

### 7. Offline Sync Engine Audit
Confirm whether the client-side outbox queue pattern (idempotent `recordId`, `syncStatus` tracking: pending/synced/failed) exists anywhere in the codebase, or if offline sync is not yet started.

## Output Requirements (`tasks.md`)
The final report must be generated in `conductor/tracks/project_state_audit/tasks.md` containing:
- **Section A**: ✅ Fully Implemented (matches spec)
- **Section B**: 🟡 Partially Implemented (exists but incomplete/incorrect)
- **Section C**: ❌ Not Started (planned but zero code found)
- **Section D**: 🚫 Out-of-Scope Code Found (needs removal — old app remnants, Cloud Functions usage, Custom Claims logic, unbounded Firestore queries)
- **Section E**: Recommended Next Track (which feature to build first based on what's missing and priority order: Auth → Servants → Attendance → Offline Sync → Results)

## Non-Functional Requirements
- Read-only analysis. Explicitly mark missing items as "Not Found" rather than guessing.
