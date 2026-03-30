# Contract: Admin Callable Operations

## Purpose

Define the observable contract for privileged account lifecycle callables used by the Flutter app.

## Covered Operations

- `createPrivilegedUser`
- `archiveManagedUser`
- `restoreManagedUser`

## Shared Contract Rules

- Caller must be authenticated.
- Caller must hold admin authorization through current custom claims.
- Caller must not be archived.
- Every successful lifecycle action must produce a committed audit event and authoritative timestamps.
- Errors must return a stable machine-readable code and a user-safe message.

## `createPrivilegedUser`

### Input Contract

- `email`: required
- `displayName`: required
- `role`: required, must be one of the supported privileged roles
- `groupId`: required when the role is group-scoped
- `assignedTeamIds`: optional list, normalized before persistence

### Success Contract

- Returns the created user identifier and role.
- Persists user profile fields with authoritative timestamps.
- Preserves existing custom claims not being changed by this operation.

### Failure Contract

- Rejects unauthenticated callers.
- Rejects non-admin callers.
- Rejects invalid role payloads.

## `archiveManagedUser`

### Input Contract

- `uid`: required target user identifier
- `reason`: optional archive reason

### Success Contract

- Marks the target account archived.
- Writes authoritative archive timestamps and actor identifiers.
- Prevents future privileged actions from the archived account.

### Failure Contract

- Rejects self-archive attempts by the current admin.
- Rejects missing or unknown targets.
- Rejects callers without admin claims.

## `restoreManagedUser`

### Input Contract

- `uid`: required target user identifier

### Success Contract

- Restores the target account.
- Marks `restorePendingPasswordReset` as active.
- Records authoritative restore timestamps and actor identifiers.
- Returns enough information for the client to route the restored user into forced password change.

### Failure Contract

- Rejects missing or unknown targets.
- Rejects callers without admin claims.

## Error Contract

The client must be able to distinguish at least these error categories:

- `unauthenticated`
- `permission-denied`
- `failed-precondition`
- `not-found`
- `invalid-argument`

## Client Expectations

- The app treats these operations as authoritative.
- Successful responses must refresh affected local admin views.
- Restored users are routed into password change before normal navigation.
