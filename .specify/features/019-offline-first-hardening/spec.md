# Feature 019: Offline-First Architecture Hardening

## Overview

Complete the offline-first architecture across the entire CSMS codebase, ensuring every feature (Student, Servant, Attendance, Team, Results) works seamlessly offline with proper Hive-first reads, sync queueing, background sync, and robust UI state handling.

## Problem Statement

The current offline implementation is **partial and inconsistent**:
- Some repositories read from Hive first (Servant), others skip Hive entirely (Team, Results)
- The SyncService only processes queues while the app is in the foreground
- Not all write operations queue mutations for later sync
- Empty/error/offline UI states are inconsistent across screens
- The `SyncStatusBanner` has been added to screens but the underlying sync pipeline has gaps

## Goals

1. **Every read** goes through Hive first, with Firestore as fallback
2. **Every write** saves to Hive immediately, then attempts Firestore, with sync queue on failure
3. **Background sync** via `workmanager` so data syncs even when app is closed
4. **Robust UI states** — every screen handles Loading, Loaded, Empty, Error, and Offline gracefully
5. **Zero data loss** — no mutation can be silently dropped

## Non-Goals

- Realtime listeners (`.snapshots()`) — violates Spark plan quota
- Full conflict resolution beyond LWW (Last-Write-Wins)
- Background sync for iOS (workmanager limitations on iOS)
