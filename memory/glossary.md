# Glossary

Workplace shorthand, acronyms, and internal language for CSMS.

## Acronyms
| Term | Meaning | Context |
|------|---------|---------|
| CSMS | ChurchServers Management System | Main application name. |
| RBAC | Role-Based Access Control | Managed via Firestore-First rules lookup. |
| SSOT | Single Source of Truth | The `servants` and `students` Firestore collections. |

## Internal Terms
| Term | Meaning |
|------|---------|
| Spark Plan | Firebase Free Tier constraints (NO Cloud Functions). |
| Firestore-First RBAC | Optimization using `get(/databases/$(database)/documents/servants/$(uid))` in security rules, as Custom Claims are incompatible with Spark Plan. |
| Zero-Cost RBAC | (Deprecated) Old attempt to use token claims; removed due to Spark Plan limits. |
| _cachedGet | Helper method injecting `Source.cache` then `Source.server` into all Firestore `.get()` requests. |
| Freshness Window | 15-minute re-validation policy for writes. |
| AuthDegraded | UI state for offline or stale permission scenarios. |