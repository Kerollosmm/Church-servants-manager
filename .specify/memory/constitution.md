<!--
SYNC IMPACT REPORT
- Version Change: 1.0.0 -> 1.1.0
- Bump Rationale: Added fixed tech stack rules, token security in flutter_secure_storage, Servant/Student role access control specs, idempotent batch write sync requirements, and Senior Flutter Engineer quality enforcement.
- Modified Principles:
  - Principle 2: "Offline-First & Data Idempotency" expanded to mandate Hive local storage, idempotent batch writes keyed by recordId (studentId_sessionId), and online Firestore sync.
  - Principle 4: "Document-Based Role-Based Access Control (RBAC)" updated to explicitly map Servant (admin) vs Student access models.
  - Principle 5: "Clean Architecture" updated to "Clean Architecture & BLoC Pattern" requiring Domain -> Data -> Presentation separation across all code outputs.
- Added Principles:
  - Principle 6: "Production-Grade Security & Token Storage" requiring flutter_secure_storage for sensitive tokens and Firestore security rule enforcement.
  - Principle 7: "Fixed Tech Stack & Senior Engineer Enforcement" mandating Flutter + BLoC + Hive + Firestore + flutter_secure_storage with strict senior-level code quality.
- Templates / Artifacts Alignment:
  - .specify/memory/constitution.md: ✅ updated
- Follow-up TODOs: None.
-->

# Project Constitution

## Overview
**Project Name:** Church Systems Management System (CSMS)
**Version:** 1.1.0
**Ratified:** 2026-05-11
**Last Amended:** 2026-07-06

This document defines the non-negotiable architectural constraints, security standards, and AI coding rules for the CSMS project. All AI agents, code generators, and developers MUST adhere to these principles on every single code output.

---

## Principles

### 1. Zero Cloud Functions (Spark Plan Compliance)
**Rule:** NEVER write, plan, or suggest the use of Firebase Cloud Functions, scheduled backend tasks, or cloud triggers.
**Rationale:** The project operates strictly on the Firebase Spark (Free) Plan without a billing account. All business logic must be executed client-side in Flutter or through administrative client scripts.

### 2. Offline-First Storage & Idempotent Batch Sync
**Rule:** All attendance and results features MUST operate 100% offline. Data MUST be written to Hive local storage first and queued for background synchronization. Online sync to Firestore MUST use idempotent batch writes keyed by deterministic Document IDs (`recordId` = `${studentId}_${sessionId}`) with Last-Write-Wins (LWW) conflict resolution.
**Rationale:** Servants frequently record attendance in locations with spotty network coverage. Idempotent batch writes ensure sync operations never produce duplicate records upon retry or connection drops.

### 3. Absolute Quota Optimization
**Rule:** NEVER perform unbounded queries or collection scans (`while(hasMore)`, `.snapshots()`, `.watch()`) on core collections for aggregations. Use single-document aggregates, cached Hive lookups, or pre-computed document fields.
**Rationale:** The Spark Plan allows only 50,000 reads per day. Iterative rule-side lookups or full collection scans will exhaust this limit rapidly.

### 4. Document-Based Role-Based Access Control (RBAC)
**Rule:** Firestore Security Rules (`firestore.rules`) MUST enforce role-based read/write access for two roles: `Servant` (admin read/write across allocated groups) and `Student` (read-only self data). Security Rules MUST read caller roles from `get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role`. Custom Claims MUST NOT be used.
**Rationale:** Custom Claims require Cloud Functions / Admin SDK which are unavailable on the Spark Plan. Cached document lookups within Firestore security rules maintain security while remaining well within daily Spark read quotas.

### 5. Clean Architecture & BLoC Pattern Enforcement
**Rule:** All Flutter application code MUST strictly adhere to Clean Architecture (`Domain -> Data -> Presentation`) and the BLoC state management pattern. UI widgets MUST NOT handle business logic or raw data transformations, and data models MUST NOT leak into presentation layers.
**Rationale:** Ensures maintainability, testability, predictable state flow, and separation of concerns across the codebase.

### 6. Production-Grade Security & Secure Token Storage
**Rule:** All sensitive credentials, session tokens, and security secrets MUST be stored exclusively in `flutter_secure_storage` (backed by iOS Keychain and Android KeyStore). Sensitive tokens MUST NEVER be stored in plain text, shared preferences, or unencrypted Hive boxes. Firestore security rules MUST protect all endpoints.
**Rationale:** Protects user privacy, authentication tokens, and administrative credentials against reverse engineering, device theft, and token compromise.

### 7. Fixed Tech Stack & Senior Engineer Quality Standard
**Rule:** The tech stack is strictly fixed: Flutter + BLoC + Hive + Firestore + `flutter_secure_storage`. The AI agent MUST act as a Senior Flutter Engineer on every code output, enforcing production-grade security, robust error handling, sound null safety, and clean architecture without exception.
**Rationale:** Prevents architectural decay, accidental dependency bloat, and fragile implementations.

---

## Governance
- **Amendments:** Any changes to this constitution must be evaluated against Firebase Spark Plan limits, offline-first sync guarantees, and tech stack constraints.
- **Versioning Policy:** Incremented following Semantic Versioning (MAJOR for breaking structural rule changes, MINOR for new principles or expanded constraints, PATCH for clarifying wording).
- **Compliance Review:** All implementation plans, feature specs, and code changes MUST undergo a "Constitution Check" to verify compliance before execution or merge.
