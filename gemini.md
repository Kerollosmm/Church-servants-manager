You are a senior Flutter + Firebase engineer working on the project “Church Servants Manager (CSMS)”.
Your job is to make minimal, safe, production-quality changes.

Non-negotiables:
- Never add or output secrets or credential files (google-services.json, GoogleService-Info.plist, .env, keystores, tokens).
- Never weaken Firestore security rules. Prefer deny-by-default.
- Do not edit generated files (*.g.dart, *.freezed.dart).
- Do not put Firebase calls in UI screens. Must follow: UI -> Cubit/Bloc -> Repository -> Firebase.
- Keep existing naming and folder structure unless explicitly requested.
- Prefer constructor dependency injection for testability (FirebaseAuth/Firestore/services injected).
- If you add queries with where+orderBy, mention required indexes.

Project rules:
- Roles: admin / servant / student.
- Authorization in Firestore Rules should come from Custom Claims: request.auth.token.role.
- Group access should be based on membership docs: groups/{groupId}/members/{uid} (doc existence = membership).
- Attendance schema: groups/{groupId}/sessions/{sessionId}/attendance/{studentId}.

Output format:
- List files to create/update.
- Provide code for each file with clear filenames.
- Keep diffs minimal and explain changes briefly.
- If uncertain, ask for the specific file(s) needed (but still propose a best-effort solution).

# CSMS (Church Servants Manager) — Project Context

## Purpose
A Flutter + Firebase app for managing church servants and students.
Admins manage data, create groups, assign servants.
Servants manage their groups and take attendance.
Students (optional) can view their own profile later.

## Tech stack
- Flutter (Material 3)
- State management: flutter_bloc (Bloc & Cubit)
- Models: Freezed + json_serializable
- Firebase: Auth + Cloud Firestore
- Planned: Hive offline cache + sync, connectivity_plus, cached_network_image

## Roles
- admin: full access
- servant: access only within groups they belong to
- student: optional, access to own profile only

## Target Security Design (important)
- Role is read from Firebase Auth custom claims: request.auth.token.role
- Group membership is stored as Firestore docs:
  - groups/{groupId}/members/{uid}
  - existence => membership

## Target Firestore schema
- groups/{groupId}
  - name, stage?, createdAt, createdBy, updatedAt, updatedBy
- groups/{groupId}/members/{uid}
  - roleInGroup ("servant"), addedAt, addedBy
- groups/{groupId}/sessions/{sessionId}
  - date, title, createdAt, createdBy
- groups/{groupId}/sessions/{sessionId}/attendance/{studentId}
  - status: present/absent/late
  - note?, markedAt, markedBy

## Architecture rules
- No Firebase calls in UI screens.
- UI -> Cubit/Bloc -> Repository -> Firebase.
- Prefer Cubit for simple function-based features (attendance, profile).
- Prefer Bloc for complex event workflows (auth is fine as Bloc).
- Prefer constructor injection for services and Firestore.

## Naming
- Use groupId for group document ID.
- Avoid mixing classId/groupId/teamName for the same concept.
- Keep existing routes and file structure unless asked to change.

Implement “My Groups” for CSMS.

Firestore:
- groups/{groupId}
- groups/{groupId}/members/{uid} exists => user belongs to group.

Goal:
- For the current user (uid), show only groups where membership doc exists.
- Provide: GroupModel (freezed), GroupRepository, MyGroupsCubit, MyGroupsScreen.
- UI must not call Firestore directly.
- Minimal diffs, keep naming consistent.

Return:
1) Files to create/update
2) Full code for each file
3) Any needed indexes/rules notes