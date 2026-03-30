# Research: CSMS Production Hardening Remediation

## Decision: Deliver the remediation in five smaller phases

**Rationale**: The audit issues span workflow availability, security, data integrity, admin lifecycle handling, and reporting performance. Splitting the work into smaller phases reduces blast radius, gives each phase a clear validation gate, and matches the user's request for phase-based planning.

**Alternatives considered**:
- Single large remediation release: rejected because it increases regression risk and makes validation too broad.
- Security-only first: rejected because attendance is currently operationally blocked by placeholder screens.

## Decision: Restore attendance operations before deeper hardening

**Rationale**: The existing attendance repository and Cubit infrastructure already contains much of the domain behavior. The highest business risk is that attendance workflows are not usable through the product interface.

**Alternatives considered**:
- Postpone UI restoration until all backend hardening is complete: rejected because the primary workflow remains non-operational.

## Decision: Use a mixed authorization strategy with lighter hot-path rule checks

**Rationale**: Coarse account state such as role and archive status should not require repeated rule-time document reads on every request. Fine-grained scope data still needs an authoritative source that reflects current assignments and relationships.

**Alternatives considered**:
- Keep all authorization decisions in document lookups: rejected for cost and latency.
- Move all scoping into token claims: rejected because assignment and linkage scope is more dynamic and must remain current.

## Decision: Make attendance concurrency protections explicit

**Rationale**: Current read-compute-write patterns can silently overwrite manual exceptions or allow conflicting active sessions. High-value attendance operations need atomic or server-mediated safeguards.

**Alternatives considered**:
- Keep merge-based client writes: rejected because they can destroy legitimate concurrent outcomes.
- Introduce offline-sync conflict resolution now: rejected because offline sync redesign is out of scope for this feature.

## Decision: Preserve mutable current-state records plus immutable audit history

**Rationale**: The app needs fast access to the current mark/session state, but production operations also require a trustworthy history of who changed what and when.

**Alternatives considered**:
- Overwrite-only current-state documents: rejected because accountability is lost.
- Full event sourcing of all attendance flows: rejected as too large for this remediation scope.

## Decision: Standardize the canonical student-to-user link

**Rationale**: The audits identified ambiguous self-read conditions caused by multiple link fields. A single canonical relationship is required for access control and identity consistency.

**Alternatives considered**:
- Preserve multiple link fields indefinitely for compatibility: rejected because it leaves authorization reasoning ambiguous.

## Decision: Bound reporting queries and optimize after data trust is restored

**Rationale**: Reporting should be rebuilt on top of reliable, audited operational data. Unbounded scans and N+1 listener patterns are acceptable as a temporary diagnosis but not as a production plan.

**Alternatives considered**:
- Optimize reporting before fixing integrity/audit gaps: rejected because fast reports on unreliable data are not valuable.

## Decision: Exclude offline sync redesign from this feature

**Rationale**: The user explicitly excluded offline sync redesign from scope. The plan may avoid making offline behavior worse, but it must not expand into queue/retry/replay architecture redesign.

**Alternatives considered**:
- Partially add queue/status behavior now: rejected because it would blur scope and create a second major architecture stream.
