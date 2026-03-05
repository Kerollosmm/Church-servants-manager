# Small Issues Plan (P2)

This file tracks non-blocking but important hardening items that improve supportability and long-term quality.

## Overall Verdict for This Group

- Status: **Can ship temporarily with risk acceptance**, but should be scheduled soon.
- Reason: these issues increase operational cost and future defect probability.

## Issue 1: Missing production telemetry/crash reporting

- Severity: P2
- Category: Reliability / Operations
- Evidence:
  - Global error handling exists in `lib/main.dart:51`, but logs are debug-gated and no telemetry backend is wired.
- Why this is bad:
  - Production crashes can go unnoticed.
  - Debugging real user issues becomes slow and expensive.
- Root cause:
  - App error handling was implemented without observability integration.
- Solution:
  1. Integrate Crashlytics (or equivalent) for uncaught errors and fatal crashes.
  2. Add breadcrumbs/context for critical flows.
  3. Define alerting thresholds (crash-free sessions, auth failure spikes).
- Acceptance criteria:
  - Crashes appear in dashboard with stack traces and release version tags.
  - Alerts trigger for severe regressions.

## Issue 2: Project structure/documentation drift

- Severity: P2
- Category: Architecture / Maintainability
- Evidence:
  - Docs reference files that are not present, e.g. in `docs/CURRENT_PROJECT_STRUCTURE.md:43` and `:229`.
  - Typoed feature path exists: `lib/features/attendace_recourd/models/attendance_record_model.dart`.
- Why this is bad:
  - New contributors can implement in wrong places.
  - Increases risk of duplicate modules and dead code.
- Root cause:
  - Documentation and folder naming were not kept synchronized with refactors.
- Solution:
  1. Normalize feature folder names and fix typos.
  2. Update project-structure docs to current state.
  3. Add lint/checklist rules for architecture conventions.
- Acceptance criteria:
  - Folder names are consistent and typo-free.
  - Docs accurately match repository layout.
  - PR checklist includes architecture compliance.

## Issue 3: App Check hardening not visible

- Severity: P2
- Category: Security / Abuse Protection
- Evidence:
  - No `firebase_app_check` dependency in `pubspec.yaml`.
  - No App Check init path in `lib/main.dart`.
- Why this is bad:
  - Backend resources are easier to abuse from scripted clients.
  - Increased risk of quota/billing attacks.
- Root cause:
  - Anti-abuse layer was not added yet in initial implementation.
- Solution:
  1. Add App Check to supported platforms.
  2. Enforce App Check in Firebase services where feasible.
  3. Roll out staged enforcement with monitoring.
- Acceptance criteria:
  - App Check tokens are issued and validated in production.
  - Unauthorized non-attested traffic is blocked.

## Execution Plan (Small)

1. Add observability (Crashlytics + alerts).
2. Clean architecture docs and naming drift.
3. Introduce App Check with staged rollout.

## Done Definition for This File

- Support/incident response has real visibility.
- Repo structure and docs are aligned.
- Baseline abuse protection is in place.
