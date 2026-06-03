# CSMS - Detailed Operations Graph

This document provides a detailed breakdown of the core operations within the CSMS app, visualized using Mermaid graphs.

## 1. Authentication & RBAC Flow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant AuthBloc
    participant FirebaseAuth
    participant SecureStorage

    User->>UI: Enters Credentials
    UI->>AuthBloc: LoginRequested(email, pass)
    AuthBloc->>FirebaseAuth: signInWithEmailAndPassword()
    FirebaseAuth-->>AuthBloc: UserCredential + JWT
    AuthBloc->>FirebaseAuth: getIdTokenResult(forceRefresh: true)
    FirebaseAuth-->>AuthBloc: Token with Custom Claims (Role)
    AuthBloc->>SecureStorage: Save token locally
    AuthBloc-->>UI: AuthenticatedState(Role)
    UI->>UI: Route to Role-Specific Dashboard (RoleUserRoute)
```

## 2. Offline-First Write & Sync Flow (The Sync Engine)

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant Repository
    participant Hive (Local)
    participant SyncService
    participant Connectivity
    participant Firestore

    User->>UI: Submit Data (e.g., Mark Attendance)
    UI->>Repository: saveRecord(record)
    
    note over Repository, Hive (Local): 1. Immediate Local Write
    Repository->>Hive (Local): write(record, syncStatus: 'pending')
    Hive (Local)-->>UI: State Updated (Instant UI response)
    
    note over SyncService, Firestore: 2. Background Sync Process
    Connectivity->>SyncService: Connection Restored Event
    SyncService->>Hive (Local): getPendingRecords()
    Hive (Local)-->>SyncService: List of pending records
    SyncService->>Firestore: batch().set(records)
    
    alt Success
        Firestore-->>SyncService: Batch Write Success
        SyncService->>Hive (Local): updateStatus(recordIds, 'synced')
    else Failure
        Firestore-->>SyncService: Write Failed
        SyncService->>Hive (Local): updateStatus(recordIds, 'failed')
        note over SyncService: Apply Exponential Backoff Retry
    end
```

## 3. Attendance Operation Flow

```mermaid
graph TD
    A[Servant Opens Session] --> B{Is Session Cached in Hive?}
    B -->|Yes| C[Render UI Instantly]
    B -->|No| D[Show Loading]
    
    C --> E{Is Device Online?}
    D --> E
    
    E -->|Yes| F[Fetch updates from Firestore]
    F --> G[Merge Remote Data into Hive]
    G --> H[Update UI via Stream]
    
    E -->|No| I[Remain in Offline Mode]
    H --> I
    
    I --> J[Servant Taps 'Mark Present']
    J --> K[Generate Deterministic ID: studentId_servantId]
    K --> L[Write to Hive: syncStatus='pending']
    L --> M[UI Updates Instantly]
```

## 4. Admin Operation Flow (e.g., Add New Servant)

```mermaid
sequenceDiagram
    participant Admin
    participant UI
    participant AdminGate
    participant AdminTeamService
    participant AuthFreshnessPolicy

    Admin->>UI: Taps 'Add Servant'
    UI->>AdminGate: Check Claims
    AdminGate-->>UI: Access Granted
    
    UI->>AuthFreshnessPolicy: canPerformWrites()
    alt Over 15 mins since auth validation
        AuthFreshnessPolicy-->>UI: Denied
        UI-->>Admin: Prompt Re-authentication
    else Within 15 mins
        AuthFreshnessPolicy-->>UI: Allowed
        UI->>AdminTeamService: addServant(details)
        AdminTeamService->>Firestore: Create Servant Document
        Firestore-->>UI: Success
    end
```

## Summary of Data Models

- **Servants**: Central profile including roles (`admin`, `servant`, `teacher`, `viewer`), tied to Firebase Auth UID.
- **AttendanceSessions**: Represents a specific service/class occurrence.
- **AttendanceRecords**: The junction record linking a `session`, a `student`, and the marking `servant`. Uses deterministic IDs to prevent duplicate entries during offline sync resolution.
