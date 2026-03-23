# Data Model: Remediated Entities

This document lists the entities whose implementation (but not schema) is being updated for stability and type safety.

## Entities
- **AuthUser**: Updating factory methods for stricter null safety and mapping.
- **StudentModel**: Ensuring all fields match the Firestore schema precisely to avoid `dynamic` casting errors.
- **AttendanceMark**: Refining equality checks (Equatable) for optimized rebuilds.
- **TeamModel**: Improving validation logic during deserialization.

## State Transitions
No changes to existing state transitions. Refactors will only move transition logic from UI to Cubits.
