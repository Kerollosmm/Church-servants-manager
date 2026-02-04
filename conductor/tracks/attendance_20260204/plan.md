# Track Plan: Implement Core Attendance Logging Feature

## Phase 1: Domain & Data Layer Setup
*Focus: Define models, entities, and repositories for attendance.*

- [~] Task: Define `AttendanceStatus` enum and `AttendanceRecord` entity in Domain layer
- [ ] Task: Create `AttendanceRepository` abstract class in Domain layer
- [ ] Task: Implement `AttendanceModel` (Data layer) with Hive and Firestore serialization (`json_serializable`, `hive_generator`)
- [ ] Task: Implement `AttendanceLocalDataSource` using Hive
- [ ] Task: Implement `AttendanceRemoteDataSource` using Firestore
- [ ] Task: Implement `AttendanceRepositoryImpl` coordinating local and remote sources
- [ ] Task: Write unit tests for `AttendanceRepositoryImpl` (sync logic)
- [ ] Task: Conductor - User Manual Verification 'Domain & Data Layer Setup' (Protocol in workflow.md)

## Phase 2: Business Logic (BLoC)
*Focus: Manage state for loading students and toggling attendance.*

- [ ] Task: Define `AttendanceEvent` and `AttendanceState`
- [ ] Task: Implement `AttendanceBloc` (LoadStudents, UpdateAttendanceStatus, SyncData)
- [ ] Task: Write unit tests for `AttendanceBloc` (mocking repository)
- [ ] Task: Conductor - User Manual Verification 'Business Logic (BLoC)' (Protocol in workflow.md)

## Phase 3: UI Implementation
*Focus: Build the screens and widgets for servants.*

- [ ] Task: specific `AttendanceListItem` widget with status toggle (using Arabic labels)
- [ ] Task: specific `AttendanceSummary` widget (counts for Present/Absent/etc.)
- [ ] Task: specific `AttendanceScreen` scaffold and BLoC integration
- [ ] Task: Implement "Offline Mode" visual indicator
- [ ] Task: Write widget tests for `AttendanceListItem` interaction
- [ ] Task: Conductor - User Manual Verification 'UI Implementation' (Protocol in workflow.md)

## Phase 4: Integration & Polish
*Focus: Connect everything and ensure localization/UX standards.*

- [ ] Task: Integrate `AttendanceScreen` into the main app navigation
- [ ] Task: Verify Arabic localization for all terms (`رصد الغياب`, etc.)
- [ ] Task: Perform manual E2E test (Log attendance offline -> Restart App -> Check persistence -> Go Online -> Check Firestore)
- [ ] Task: Conductor - User Manual Verification 'Integration & Polish' (Protocol in workflow.md)
