# Project Constitution

## Overview
**Project Name:** Church Systems Management System (CSMS)
**Version:** 1.0.0
**Last Amended:** 2026-05-11

This document defines the non-negotiable architectural constraints and AI coding rules for the CSMS project. All AI agents, code generators, and developers MUST adhere to these principles.

---

## Principles

### 1. Zero Cloud Functions (Spark Plan Compliance)
**Rule:** NEVER write, plan, or suggest the use of Firebase Cloud Functions, scheduled tasks, or backend triggers.
**Rationale:** The project operates strictly on the Firebase Spark (Free) Plan without a billing account. All logic must be handled on the client-side or through administrative scripts.

### 2. Offline-First & Data Idempotency
**Rule:** All features MUST work 100% offline. Data must be written to local storage (Hive) first, then queued for synchronization.
**Rationale:** Target environments suffer from unreliable internet. Sync operations must use deterministic Document IDs (e.g., `recordId` = `studentId_sessionId`) and Last-Write-Wins (LWW) resolution to prevent duplicate data on retry.

### 3. Absolute Quota Optimization
**Rule:** NEVER perform unbounded queries or collection scans (`while(hasMore)`, `.snapshots()`, `.watch()`) on core collections for aggregations. Use single-document aggregates or Custom Claims.
**Rationale:** The Spark Plan allows only 50,000 reads per day. Iterative rule-side lookups or full table scans will exhaust this limit in minutes.

### 4. Zero-Cost Role-Based Access Control (RBAC)
**Rule:** Security Rules (`firestore.rules`) MUST rely exclusively on JWT Custom Claims (`request.auth.token.role`) for authorization.
**Rationale:** Calling `get()` inside a security rule consumes a read quota. Custom Claims cost zero database reads.

### 5. Clean Architecture
**Rule:** Follow the established `Domain -> Data -> Presentation` layer structure using BLoC.
**Rationale:** Maintains predictability, testability, and separation of concerns.

---

## Governance
- **Amendments:** Any changes to this constitution must be evaluated against the Firebase Spark Plan constraints.
- **Compliance:** All implementation plans (like `plan.md`) must undergo a "Constitution Check" to verify adherence to these principles before execution.
