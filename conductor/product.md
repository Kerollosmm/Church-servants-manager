# Initial Concept
CSMS is a Flutter + Firebase offline-first mobile app for church attendance and results management. Architecture: Clean Architecture + BLoC + Hive + Firestore. Spark Plan constraints: NO Cloud Functions. Server-side enforcement relies solely on Firestore Security Rules (Firestore-first RBAC via user document roles). Two roles: Servant (admin) and Student. Servants record attendance offline, sync to Firestore when online using client-side idempotent batch writes keyed by recordId. All tokens in flutter_secure_storage. Tech stack is fixed. The agent must act as a Flutter senior engineer enforcing clean architecture, BLoC patterns, offline-first design, and production-grade security on every single code output.

# Product Guide - CSMS (Church Servants Management System)

## Vision & Purpose
CSMS (Church Servants Management System) is an offline-first, highly secure mobile application built for church communities operating on Firebase Spark Plan (Free Tier). It empowers Servants (teachers/admins) to reliably track student attendance, manage educational/service results, and organize teams even in areas with zero internet connectivity. When connectivity is restored, all offline transactions seamlessly sync to Firebase Cloud Firestore using client-side idempotent, conflict-free batch operations without relying on Cloud Functions.

## Core Target Users & Roles
1. **Servants (Admins / Teachers)**:
   - Record offline attendance per class/session.
   - Manage student records, grades, and team assignments.
   - Sync offline data to Firestore when online via client-side batch writes.
   - Full read/write access controlled strictly via Firestore Security Rules (Firestore-first RBAC).
2. **Students**:
   - View personal attendance history, announcements, and results.
   - Read-only access to their own data via role-scoped Firestore Security Rules.

## Essential Features
- **Offline-First Attendance Tracking**: Record attendance (Present, Absent, Excused, Late) locally using Hive storage without network dependency.
- **Client-Side Idempotent Data Sync**: Queue local mutations in a client outbox queue and commit to Firestore using idempotent batch writes keyed by `recordId` to prevent duplicate writes.
- **Spark-Plan Security & RBAC**:
  - Secure token & credentials storage in `flutter_secure_storage`.
  - Firestore-first RBAC enforced via Firestore Security Rules reading user roles from `/users/{userId}`. Zero reliance on Cloud Functions.
- **Clean Architecture & Predictable State**: Strict separation across Data (Repositories, Hive/Firestore Datasources), Domain (Entities, Use Cases), and Presentation (BLoC/Cubit).

## Success Criteria
- Zero data loss during offline-to-online transitions under Spark plan quotas.
- Idempotent sync handles network interruptions gracefully without duplicate records or Cloud Functions.
- UI responds instantly (< 16ms frame target) using local Hive cache.
- Strict compliance with Clean Architecture and Flutter BLoC best practices.
