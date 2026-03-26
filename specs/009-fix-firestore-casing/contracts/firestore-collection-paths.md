# Contract: Firestore Collection Paths

## Purpose

Define the canonical Firestore collection names that all app, backend, test, and configuration artifacts must use for this repository.

## Canonical Names

| Logical Collection | Required Path Value | Notes |
|---|---|---|
| User profiles | `users` | Used for authenticated user documents and role/profile lookups |
| Student records | `students` | Used for student documents and linked user lookups |
| Class/team records | `classes` | Legacy collection name retained for team data |

## In-Scope Consumers

- Shared constants in `lib/core/constants/firestore_collections.dart`
- Flutter repositories and services that read or write Firestore collections
- Firebase Cloud Functions constants and Firestore document access
- Automated tests that seed or assert Firestore data
- `firestore.indexes.json` collection group definitions

## Prohibited Values

- `Users`
- `Students`
- `Classes`

## Compatibility Rules

- Keep the existing Dart class name `FirestoreCollections`.
- Keep the existing constant member names `users`, `students`, and `classes`.
- Change only the string values representing the Firestore path.

## Verification Rules

- Repo-wide search for quoted `Users`, `Students`, and `Classes` Firestore path literals returns no remaining in-scope matches after implementation.
- All in-scope consumers resolve to the lowercase canonical names above.
