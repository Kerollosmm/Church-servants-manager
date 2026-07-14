# Glossary

Workplace shorthand, acronyms, and internal language for CSMS.

## Acronyms
| Term | Meaning | Context |
|------|---------|---------|
| CSMS | ChurchServers Management System | Main application name. |
| RBAC | Role-Based Access Control | Managed via Firestore-First rules lookup. |
| SSOT | Single Source of Truth | The `servants` and `students` Firestore collections. |
| DLQ | Dead Letter Queue | Hive-backed store for sync entries that failed after max retries. |

## Internal Terms
| Term | Meaning |
|------|---------|
| Spark Plan | Firebase Free Tier constraints (NO Cloud Functions). |
| Firestore-First RBAC | Optimization using `get(/databases/$(database)/documents/servants/$(uid))` in security rules, as Custom Claims are incompatible with Spark Plan. |
| Zero-Cost RBAC | (Deprecated) Old attempt to use token claims; removed due to Spark Plan limits. |
| _cachedGet | Helper method injecting `Source.cache` then `Source.server` into all Firestore `.get()` requests. |
| Freshness Window | 15-minute re-validation policy for writes. |
| AuthDegraded | UI state for offline or stale permission scenarios. |
| Outbox Pattern | Sync architecture: local write first (Hive), then async Firestore sync. |
| SyncEngineStatus | Renamed from `SyncStatus` to avoid naming conflict with `enums.dart SyncStatus` (pending/synced/failed). |
| HivePruningService | 30-day data retention policy for synced Hive boxes. Moves stale entries to DLQ. |
| Exponential Backoff | Retry delay: `min(2^retry * baseMs + jitter, 30s)`. Used in SyncService for failed entries. |
| Workmanager | Background sync task registered for periodic runs (15-min, Android only reliable). |
| CLEAR_ATTENDANCE loop | Known bug: sync handler routes back to repository's enqueue-only method instead of Firestore delete. |

## Conductor Tracks
| Track | Date | Description |
|-------|------|-------------|
| `project-state-audit` | Jun 2026 | Comprehensive gap analysis of CSMS project health |
| `codebase-hardening` | Jun–Jul 2026 | Remediate architectural and security audit findings |
