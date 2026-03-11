# Security Review Report

## Executive Summary

This repository has a sound direction in that it uses Firestore rules and callable Cloud Functions for privileged account operations, but there are several security gaps in how those controls are deployed and enforced.

The highest-risk issues are:

1. Firestore rules are present in the repo but are not wired into `firebase.json`, which creates a real risk that production is running stale or default rules.
2. Admin callable functions trust stale `role` custom claims and do not fully re-check current Firestore state, so previously-admin users can retain backend privilege after demotion or archival.
3. The client intentionally serves cached data and cached roles during degraded auth states, which can keep previously synced student/servant data visible after access revocation.

This review was static only. I did not validate the currently deployed Firebase project configuration.

## High Severity

### SEC-01: Firestore rules are not configured for deployment

Impact: The repository's restrictive Firestore policy may never be deployed, leaving production on stale or default rules and breaking the core authz boundary for the app.

Evidence:

- `C:\Users\KimoStore\church_managment_system\firebase.json:1-26` defines only `functions` and `flutter`; there is no `firestore.rules` or `firestore.indexes` deployment stanza.
- `C:\Users\KimoStore\church_managment_system\firestore.rules:1` contains a full access-control policy that appears intended to protect the app.

Why this matters:

- The app relies heavily on Firestore rules for role enforcement (`admin`, `servant`, `student`) and scoping by `groupId` / `assignedTeamIds`.
- If `firebase deploy` is run from this repo as-is, the rules file in source control is not the source of truth for production enforcement.

Recommended fix:

- Add a `firestore` block to `firebase.json`:
  - `"firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" }`
- Treat rules deployment as mandatory in CI/CD, not manual.

### SEC-02: Privileged callable functions authorize from stale admin claims and do not revalidate current account state

Impact: A user who ever received an admin custom claim can continue calling privileged backend functions after Firestore demotion, and possibly after archival until token expiry, allowing continued user provisioning and account lifecycle actions.

Evidence:

- `C:\Users\KimoStore\church_managment_system\functions\src\index.ts:18-35`
  - `requireAdmin()` returns immediately when `auth.token['role'] === 'admin'`.
  - It does not re-check `isArchived`, does not confirm the current Firestore role when the token says admin, and does not verify claim freshness.
- `C:\Users\KimoStore\church_managment_system\functions\src\index.ts:52`
  - Custom claims are set only during `createPrivilegedUser`.
- `C:\Users\KimoStore\church_managment_system\functions\src\index.ts:104-110`
  - Archival disables the account and revokes refresh tokens, but `requireAdmin()` still trusts any already-issued admin token on subsequent callable requests.
- `C:\Users\KimoStore\church_managment_system\firestore.rules:34-40`
  - Firestore rules treat archived users as non-admin/non-servant, so callable authz is weaker than Firestore authz.
- `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\student_linked_user_sync_service.dart:38-58`
  - Role changes are written directly to `Users/{uid}` in Firestore.
- `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\student_linked_user_sync_service.dart:99-109`
  - The batch updates Firestore only; there is no Admin SDK claim sync.
- `C:\Users\KimoStore\church_managment_system\lib\features\servant\presentation\widgets\servant_edit_form_sections.dart:77-94`
  - The admin UI allows promoting an existing user to `UserRole.admin`.
- `C:\Users\KimoStore\church_managment_system\lib\features\servant\data\repo\servant_data_repository.dart:72-85`
  - Role is normalized into the Firestore `Users` document.
- `C:\Users\KimoStore\church_managment_system\lib\features\servant\data\repo\servant_data_repository.dart:367-373`
  - Editing a servant writes the new role directly to Firestore.

Why this matters:

- Backend privilege is effectively granted by a mix of Firestore state and custom claims, but revocation is not synchronized.
- Demoting an admin in Firestore does not remove their admin custom claim.
- Archiving an admin updates Firestore and revokes refresh tokens, but old ID tokens can still be valid until expiry if the backend trusts claims without checking current account state.

Recommended fix:

- Make `requireAdmin()` always load the current `Users/{uid}` document and require:
  - `role == 'admin'`
  - `isArchived != true`
- For privileged callables, optionally verify the Auth user is not disabled before proceeding.
- Move admin role assignment/removal behind a dedicated backend function that also updates custom claims and revokes refresh tokens immediately.

## Medium Severity

### SEC-03: Cached roles and persistent Firestore cache keep data visible after permission revocation

Impact: A demoted or offboarded user can continue viewing previously synced student/servant data from local cache when refresh fails or the device is offline.

Evidence:

- `C:\Users\KimoStore\church_managment_system\lib\core\di\injection.dart:26-33`
  - Firestore offline persistence is explicitly enabled.
- `C:\Users\KimoStore\church_managment_system\lib\features\auth\presentation\bloc\auth_bloc.dart:13`
  - Degraded mode explicitly says it will show "last synced permissions."
- `C:\Users\KimoStore\church_managment_system\lib\features\auth\presentation\bloc\auth_bloc.dart:228-250`
  - On refresh failure, the app reuses `lastKnownAppUser` and emits `AuthDegraded`.
- `C:\Users\KimoStore\church_managment_system\lib\role_user_route.dart:24-35`
  - Degraded servants and students are still routed into their normal dashboards.
- `C:\Users\KimoStore\church_managment_system\lib\role_user_route.dart:87-91`
  - `AuthDegraded` is treated as authenticated for routing.
- `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\student_query_service.dart:63-80`
  - Student queries explicitly return cache results before server results.
- `C:\Users\KimoStore\church_managment_system\lib\features\servant\data\repo\servant_data_repository.dart:147-166`
  - Servant queries also return cache results before server results.

Why this matters:

- Firestore rules protect the server, but they do not retroactively erase already-synced local cache.
- On a lost/shared device or after role revocation, cached rosters and profile data can remain readable locally.

Recommended fix:

- For sensitive collections, prefer server-only reads after sign-in and after any permission refresh failure.
- On sign-out, archival, or permission downgrade, clear local persistence with a terminate/clearPersistence flow before allowing another session.
- Consider refusing degraded access for servant/student dashboards when the dataset contains sensitive student information.

## Low Severity

### SEC-04: `Users.isEmailVerified` is user-controlled in Firestore

Impact: Any workflow that trusts the Firestore `isEmailVerified` field can be misled by a user forging their verification state in their own profile document.

Evidence:

- `C:\Users\KimoStore\church_managment_system\firestore.rules:92-101`
  - Self-created `Users/{uid}` documents can set `isEmailVerified` arbitrarily.
- `C:\Users\KimoStore\church_managment_system\firestore.rules:104-118`
  - Self-updates can also modify `isEmailVerified`.
- `C:\Users\KimoStore\church_managment_system\lib\features\auth\data\services\auth_user_profile_store.dart:39-50`
  - The app persists `isEmailVerified` into Firestore.
- `C:\Users\KimoStore\church_managment_system\lib\features\auth\data\services\firebase_auth_provider.dart:303-308`
  - The field is later synchronized from Firebase Auth, but only when that code path runs successfully.

Why this matters:

- Current login enforcement mainly relies on Firebase Auth, which limits immediate impact.
- The Firestore field still looks authoritative and can easily become a future authz bug if reused in rules, admin tooling, or reporting.

Recommended fix:

- Remove `isEmailVerified` from self-writable rule paths.
- If the field is needed in Firestore, update it only from a trusted backend trigger or callable function based on the Auth user record.

## Additional Notes

- I did not find a hardcoded backend service account, private key, or obvious secret token committed in the repository during this review.
- The Firebase API keys in client config are normal public client identifiers and are not, by themselves, a secret exposure finding.
