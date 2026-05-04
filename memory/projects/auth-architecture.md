# CSMS Architecture

**Codename:** CSMS
**Status:** Active, Refactored Auth Logic

## Core Architecture
- **Clean Architecture:** Separated into `data`, `domain`, and `presentation` layers.
- **Identity vs Profile:** Firebase handles Auth (Identity), Firestore handles metadata (Profile).
- **RBAC:** Custom Claims are the Single Source of Truth (SSOT) for roles, archiving, and team access.
- **Spark Plan Constraints:** No Cloud Functions. All logic is client-side. Optimized for zero-cost RBAC using claims in Firestore rules.

## Authentication System
- **Provider:** `FirebaseIdentityProvider` (exposes `authStateChanges` and `idTokenChanges`).
- **Repository:** `FirebaseAuthRepository` (merges JWT claims with Firestore profiles).
- **Security:** `AuthFreshnessPolicy` (15-min write window).
- **UI States:** `AuthAuthenticated`, `AuthDegraded` (read-only/offline), `AuthArchived`.
- **Gating:** `AdminGate` ensures administrative access with session freshness.

## Implementation Details
- Claims authoritative for: `role`, `isArchived`, `assignedTeamIds`.
- Firestore TTL: 1-hour cache for user profiles.
- Offline support: `AuthDegraded` state warns about stale permissions.
