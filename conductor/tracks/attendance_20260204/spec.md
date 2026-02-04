# Track Specification: Implement Core Attendance Logging Feature

## Overview
This track focuses on building the foundational capability for servants to log attendance for students in a specific session. It includes creating the UI for selecting a session/date, displaying a list of students, and toggling their attendance status (Present, Absent, Late, Excused). The implementation will follow the project's Clean Architecture structure using BLoC for state management.

## Goals
*   Enable servants to view a list of students for a specific group/class.
*   Allow marking students as Present, Absent, Late, or Excused.
*   Save attendance records locally using Hive (offline-first).
*   Sync attendance data to Firestore when online.
*   Provide immediate visual feedback for attendance actions.

## User Stories
*   **As a Servant**, I want to see a list of students in my class so that I can take attendance.
*   **As a Servant**, I want to tap on a student's name to change their attendance status (toggle or dropdown) so I can quickly mark them.
*   **As a Servant**, I want to see a summary of attendance (e.g., "15 Present, 2 Absent") for the current session.
*   **As a Servant**, I want my changes to be saved automatically so I don't lose data.
*   **As an Admin**, I want to view the attendance records logged by servants.

## Technical Requirements
*   **Architecture:** Clean Architecture (Presentation, Domain, Data).
*   **State Management:** `flutter_bloc` for handling UI states (Loading, Success, Error).
*   **Local Storage:** `hive` for persisting attendance data offline.
*   **Remote Storage:** `cloud_firestore` for syncing data.
*   **Models:**
    *   `AttendanceRecord`: ID, studentId, sessionId, date, status, notes.
    *   `Student` (Reference): minimal data needed for the list (id, name, photoUrl).
*   **UI Components:**
    *   `AttendanceScreen`: Main view.
    *   `StudentListItem`: Widget displaying student info and attendance toggle.
    *   `AttendanceSummary`: Widget showing counts.

## Localization Constraints (Arabic)
*   **Confirm:** `تأكيد`
*   **Delete:** `حذف`
*   **Log Attendance:** `رصد الغياب`
*   **Present:** `حاضر`
*   **Absent:** `غائب`
*   **Late:** `متأخر`
*   **Excused:** `عذر`

## Success Metrics
*   Servants can log attendance for a class of 20 students in under 2 minutes.
*   Data persists across app restarts (Hive verification).
*   Data syncs to Firestore within 5 seconds of regaining connectivity.
