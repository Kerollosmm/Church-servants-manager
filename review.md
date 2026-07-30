# ChurchServers Management System (CSMS) Code Review Guidelines

This document defines the mandatory repository-level review standards for **Layer 2 Local AI Code Reviews** and **Layer 4 Human Reviews**.

---

## 🏛️ Core Architectural Principles (Non-Negotiable)

1. **Offline-First Single Source of Truth (SSOT)**:
   - Hive is the single source of truth for the UI.
   - All UI reads must read from Hive. Writes MUST go to Hive first before queuing sync to Firestore.
   - Attendance and core servant workflows must function completely offline without network latency or dependencies.

2. **Spark Plan Constraints (Firebase Free Tier)**:
   - **NO Cloud Functions**: All business logic, validation, and processing must be executed in-app.
   - **Minimize Firestore Reads/Writes**: Aggressively cache data in Hive. Avoid wasteful queries or unindexed scans.
   - Use batch operations (`WriteBatch`) for multi-document updates.

3. **Role-Based Access Control (RBAC)**:
   - Enforce RBAC via Firebase Custom Claims (with Firestore Security Rules fallback).
   - Student role must ONLY access their own records.
   - Servant/Admin roles must be restricted to authorized operational scope.
   - Never rely exclusively on client-side UI checks for authorization.

4. **BLoC & Clean Architecture**:
   - Strictly separate presentation (UI) from business logic (BLoC/Cubit) and data sources.
   - Use `sealed class` for BLoC states. Always handle `Initial`, `Loading`, `Success`, `Error`, and `Empty` states.
   - Pass dependencies via constructor; NEVER call `GetIt.I` or `getIt<>()` inside Widget `build()` methods.

---

## 🔍 The 4 Review Pillars

Every code diff must be evaluated against the following four pillars:

### 1. Correctness & Feature Completeness
- Does the code fulfill the task requirements without regressions?
- Are boundary states (null, empty list, network error, initial load) handled safely?
- Is sync status tracked (`syncStatus: pending | synced | failed`) with idempotent updates using `recordId`?

### 2. Security & Data Protection
- **No Hardcoded Secrets**: Use `--dart-define` or environment variables for API keys or sensitive values.
- **No PII in Logs**: Do not log names, emails, phone numbers, or user IDs.
- **No Silent Exception Catching**: Every `catch` block MUST log using `developer.log(e.toString(), error: e, stackTrace: stackTrace)`. No empty catch blocks.
- **Firestore Security Rules**: Ensure new collections or fields have matching rule guards.

### 3. Code Simplicity & Anti-Verbosity (Owain Lewis Principle)
- **Eliminate AI Bloat**: Remove superfluous helper abstractions, redundant try/catch wrappers, and over-engineered boilerplate.
- **Readability**: Is the code straightforward, self-documenting, and concise?
- **No Null Assertions (`!`)**: Use `??`, `?.`, or pattern matching instead.

### 4. Resilience & Concurrency under Load
- **Unawaited Futures**: Every `unawaited()` call MUST attach a `.catchError()` handler.
- **Resource Disposal**: Ensure all BLoCs, StreamSubscriptions, Controllers, and Hive boxes are properly closed/disposed.
- **Race Condition Prevention**: Ensure debouncing or UI lockouts prevent rapid double-tapping on form submissions or attendance toggles.

---

## 📋 Finding Classification

Report code review findings strictly under two categories:

- 🚨 **MUST FIX**: Security flaws, breaking architectural bugs, unhandled exceptions, memory leaks, missing offline sync, Spark plan rule violations.
- ⚠️ **MINOR / NICE TO HAVE**: Style improvements, minor refactorings, non-blocking cleanup, documentation suggestions.
