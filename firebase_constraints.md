---
name: Firebase Spark Plan Constraints
description: Project uses Spark (free) plan with no payment method, no Cloud Functions access, low request budget
type: project
originSessionId: a4b4b195-ad78-49a3-95a7-a46396182542
---

**Firebase Plan**: Spark (free tier)

- No payment method configured
- **Cloud Functions NOT available** (cannot use `functions/src/triggers/sync_user_claims.ts`)
- Low request quotas - must minimize Firestore reads/writes
- Same app functionality required despite constraints

**Implications for Architecture**:

1. Cannot rely on Cloud Functions for:
   - Automatic claim sync triggers (onDocumentUpdated/onDocumentCreated)
   - Batch operations
   - Scheduled tasks
2. Must optimize for minimal Firestore operations:
   - Custom Claims RBAC requires a server-side Admin SDK (Cloud Functions/Cloud Run/App Engine or external backend) and cannot be created/updated on Spark plan.
   - Alternatives: 
      (1) Upgrade to a paid backend to use Firebase custom claims. 
      (2) Commit to a Firestore-first RBAC approach (store roles/permissions in Firestore and read/validate them client-side with appropriate security rules and caching).
   - Offline-first implementation (Phase 2) must prioritize local-first, sync-on-demand
   - Pagination/lazy loading essential to reduce queries
3. Client-side must handle:
   - Manual sync triggers instead of automatic triggers

**Why This Matters**:

- **TODO**: Resolve RBAC approach (Custom Claims vs alternative) and document the chosen pattern.
- **TODO**: Adjust any tasks that assume Cloud Functions availability to be conditional or provide fallbacks.
- **TODO**: Mark cost-sensitive optimizations (Custom Claims rules, offline-first sync, API-call minimization) as required only after the RBAC resolution is committed.
- Production readiness plan assumes Cloud Functions availability - adjust tasks that depend on them
- Offline-first sync becomes critical for resilience under rate limits
- Every API call must be intentional and cost-efficient. Validate non-negative inputs in server-side monetary calculation functions.

**How to Apply**:

- Remove dependency on Cloud Functions triggers for claim sync
- Custom Claims migration requires a backend/Admin SDK and must be scheduled only when server-side access is available. Alternatively, use a Firestore-first RBAC approach.
- Implement client token refresh instructions while performing claim updates server-side via Admin SDK.
- Emphasize pagination, batching, local-first caching
- Test with actual Spark plan quotas to ensure under limits
