# MODIFICATION DESIGN: CSMS Offline-First Architecture

## Overview
This document defines the architecture and implementation strategy for transforming the Church Servers Management System (CSMS) into a true **offline-first** application. It prioritizes data integrity on unstable church WiFi, security via hard freshness gates, and cost-efficiency on the Firebase Spark plan.

## Technical Design

### 1. Local Storage Layer (Hive)
- **Schema:** 
  - `attendance_records`: Stores individual marks with `syncStatus` (pending, synced, failed).
  - `user_profile`: Cached `AuthUser` metadata.
  - `last_sync_metadata`: Tracks global sync timestamps and session freshness.
- **Principle:** Hive is the **Single Source of Truth (SSOT)** for the UI. Firestore acts as a remote mirror and synchronization hub.

### 2. Reactive State Management (BLoC)
- **Flow:** `UI -> BLoC -> Repository (Hive Write) -> SyncEngine (Online Push)`.
- **States:** 
  - `OfflineAuthenticated`: Session restored from cache within grace window.
  - `Syncing`: Background process active.
  - `AuthUnauthenticated`: Session expired (>24h) or manual logout.

### 3. Synchronization Engine
- **Idempotency:** Uses `recordId` (UUID v4) as the Firestore Document ID. Retrying a write with the same ID results in a `set(merge: true)`, preventing duplicates.
- **Batching:** Collects up to 500 `pending` records and pushes them in a single `Firestore.batch()` call.
- **Exponential Backoff:** If sync fails due to network/quota, retry at intervals: 1s, 2s, 4s, 8s, then mark as `failed` for manual user retry.
- **Conflict Resolution:** "Last-Write-Wins" using `clientUpdatedAt` timestamp fields.

### 4. Hardened Security Gates
- **Session Restore:** Allowed only if `AuthFreshnessPolicy` verifies the last online login was < 24 hours ago.
- **Manual Login:** Prohibited while offline (requires live Firebase Auth verification).
- **Grace Window Expiry:** Forces redirection to Login screen and clears local sensitive cache.

---

## Project Management Breakdown

### Epic 1: Local Foundation & Hive Schema
**User Story:** As a servant, I want my data saved instantly even without WiFi, so I never lose progress.
- **Task 1.1: Hive Schema Implementation (P0)**
  - Subtask: Create `AttendanceRecord` Hive Adapter with `syncStatus`.
  - Subtask: Implement `AuthUser` encryption in Hive.
- **Task 1.2: Repository Layer Refactor (P0)**
  - Subtask: Update `AttendanceRepository` to write to Hive before Firestore.
  - Subtask: Implement "Read Hive first" logic for all list views.

### Epic 2: Secure Session Restoration
**User Story:** As a servant, I want to reopen the app and keep working while offline, but only if my session is still secure.
- **Task 2.1: AuthFreshness Gate integration (P0)**
  - Subtask: Wire `AuthFreshnessPolicy` into `AuthBloc.CheckStatus`.
  - Subtask: Implement auto-logout when grace window (>24h) expires.
- **Task 2.2: Offline UI Feedback (P1)**
  - Subtask: Add `OfflineAuthenticated` state and "Working Offline" banner.

### Epic 3: Idempotent Sync Engine
**User Story:** As the system, I want to sync local data to the cloud automatically when WiFi returns without creating duplicates.
- **Task 3.1: Connectivity-Aware Sync Engine (P0)**
  - Subtask: Listen to `connectivity_plus` streams.
  - Subtask: Implement `SyncPendingRecords` event with `Firestore.batch()`.
- **Task 3.2: Error Handling & Retry (P1)**
  - Subtask: Implement exponential backoff logic.
  - Subtask: Add `syncStatus` visual indicators (pending/failed icon) on list cards.

### Epic 4: Spark Plan & Conflict Resolution
**User Story:** As an admin, I want the system to resolve conflicts automatically if two servants edit the same record.
- **Task 4.1: Conflict Strategy (P1)**
  - Subtask: Add `clientUpdatedAt` to all models.
  - Subtask: Implement "Last-Write-Wins" logic in `SyncService`.
- **Task 4.2: Quota Optimization (P1)**
  - Subtask: Verify zero Cloud Functions usage.
  - Subtask: Implement 1h TTL for profile re-validation.

---

## Sprint Mapping

| Sprint | Goal | Key Deliverables |
|--------|------|-----------------|
| **Sprint A** | Local Storage & Security | Hive Adapters, Repository Local-First, Freshness Gate |
| **Sprint B** | The Sync Engine | Connectivity Listener, Batch Sync, Idempotent Writes |
| **Sprint C** | Reliability & Feedback | Exponential Backoff, Conflict Resolution, Sync UI Indicators |

## Research References
- [Hive Documentation: Encrypted Boxes](https://docs.hivedb.dev/#/advanced/encrypted_box)
- [Firestore: Transactions and Batched Writes](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Exponential Backoff Algorithm (Dart/Flutter)](https://pub.dev/packages/retry)
