# Technology Stack - CSMS

## Core Framework & Language
- **Language**: Dart (SDK ^3.9.2)
- **Framework**: Flutter (3.x+)

## Architecture & State Management
- **Architecture Pattern**: Clean Architecture (Presentation, Domain, Data)
- **State Management**: `flutter_bloc` (^9.1.1) with `equatable` (^2.0.8) / `freezed`
- **Dependency Injection**: `get_it` (^9.2.1), `injectable` (^2.7.1+4)

## Offline-First & Storage
- **Local Persistence**: `hive` (^2.2.3), `hive_flutter` (^1.1.0) for offline caching of attendance records, user entities, and outbox queue.
- **Secure Credentials Storage**: `flutter_secure_storage` (^10.0.0) for storing auth tokens, session state, and encryption keys.

## Backend & Cloud Services (Spark Plan - No Cloud Functions)
- **Database**: Cloud Firestore (`cloud_firestore` ^6.2.0) with offline persistence and client-driven batch writes.
- **Authentication**: Firebase Auth (`firebase_auth` ^6.2.0) with client-side token refresh.
- **Security Rules**: Granular Firestore Security Rules enforcing role-based read/write access (Firestore-first RBAC evaluating user role from `/users/{userId}`). **Cloud Functions completely excluded (Spark Free Tier)**.

## Network & Sync Utilities
- **Connectivity Monitoring**: `connectivity_plus` (^7.1.1)
- **Background Sync**: Client-side execution via `workmanager` (^0.9.0+3) or network listener.
- **Functional Error Handling**: `dartz` (^0.10.1) for `Either<Failure, T>` return types.
- **Unique Identification**: `uuid` (^4.5.3) for generating client-side idempotent `recordId` keys.
