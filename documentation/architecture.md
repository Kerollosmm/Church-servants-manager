# CSMS - Architectural Overview

## 1. Introduction
The Church Management System (CSMS) is a production-grade Flutter application backed by Firebase. It is designed to manage church services, servants, students, and attendance. The most critical constraint of this system is its **Offline-First** nature, catering to environments with unstable internet connections (like church Wi-Fi).

## 2. Technology Stack
- **Frontend**: Flutter (Cross-platform)
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Local Storage (Offline)**: Hive (Encrypted, fast key-value store)
- **Remote Backend**: Firebase (Spark Free Tier)
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Crashlytics
- **Dependency Injection**: `get_it` + `injectable`
- **Routing**: GoRouter (Declarative, role-guarded)

*Note: Firebase Cloud Functions are strictly avoided to remain within the Spark plan limits.*

## 3. Core Architectural Patterns

### Clean Architecture
The application strictly adheres to Clean Architecture principles, separated into features (e.g., `auth`, `attendance`, `servant`, `student`, `admin`).
Each feature contains:
- **Domain Layer**: Entities, Use Cases, and Repository Interfaces (Pure Dart).
- **Data Layer**: Remote/Local Data Sources, Models, and Repository Implementations.
- **Presentation Layer**: BLoC/Cubit state management, UI Widgets, and Pages.

### Offline-First & Data Persistence
CSMS currently uses a hybrid persistence strategy optimized for the Spark plan:
1. **Firestore Local Persistence**: The primary mechanism for offline capabilities. Firestore is configured to persist data locally, enabling standard queries to work without an internet connection.
2. **Cache-First Pattern**: Reads prioritize `Source.cache` (Firestore local cache) for instant UI rendering and to protect Firestore read quotas. Remote data is fetched to update the cache in the background or during explicit refreshes.
3. **Write-Through**: Writes are sent to Firestore immediately. Firestore's client SDK handles the queuing and eventual sync when connectivity is restored.
4. **Hive (Target Architecture)**: While Firestore persistence handles current needs, Hive is the designated target for future phases requiring complex multi-collection synchronization, manual conflict resolution, or highly optimized local-first data structures.
5. **Idempotency**: Firestore document IDs use deterministic formats (e.g., `studentId_servantId` for attendance marks) to prevent duplicate entries during sync retries.

### Role-Based Access Control (RBAC)
Roles (`admin`, `servant`, `teacher`, `viewer`) are enforced using **Firebase Custom Claims** embedded in the user's JWT. 
- This ensures zero-cost authorization checks (no extra Firestore reads are needed to verify a user's role).
- Routes are protected via `AdminGate` and `RoleUserRoute`.

### Security Constraints
- **Auth Freshness Policy**: Sensitive write operations are restricted to a 15-minute window following the last authentication validation.
- **Firestore Security Rules**: Directly enforce RBAC rules matching the custom claims.
