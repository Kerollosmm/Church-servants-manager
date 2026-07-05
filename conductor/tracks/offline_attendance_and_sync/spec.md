# Track Spec: Offline Attendance & Idempotent Client Sync

## 1. Context & Business Goal
Implement an offline-first attendance tracking system for Servants in CSMS running under Firebase Spark plan (free tier). Servants must be able to record attendance for students offline, store records locally in Hive, queue mutations in a client-side outbox queue, and flush the queue to Cloud Firestore using idempotent batch writes (`recordId`) when network connectivity is restored.

## 2. Requirements & User Stories
- **US-1 (Servant Offline Attendance)**: As a Servant, I want to record attendance (Present, Absent, Excused, Late) for my team/class while offline, so that class management is never blocked by poor network coverage.
- **US-2 (Client Outbox Queue)**: As a system, offline attendance transactions must be stored in a Hive outbox queue with client-generated UUID `recordId`s.
- **US-3 (Idempotent Sync)**: As a system, when internet connection is active, the outbox queue must be drained in batches (`cloud_firestore` `WriteBatch`) writing to `/attendance/{recordId}`. Duplicate execution or retries must be idempotent.
- **US-4 (Spark Plan Enforcement)**: Zero reliance on Cloud Functions. All validation, payload formatting, outbox management, and batch operations are executed client-side in Flutter. Security enforced server-side via `firestore.rules`.

## 3. DoD (Definition of Done)
- Attendance state recorded instantly in Hive local box.
- Client outbox persists pending records safely across app restarts.
- Auto-sync drains outbox on connectivity restored event using Firestore `set()` (merge: true) keyed by `recordId`.
- Unit tests verify outbox queueing, state transitions, and idempotency.
