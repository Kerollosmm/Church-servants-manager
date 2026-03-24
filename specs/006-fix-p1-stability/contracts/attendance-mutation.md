# Interface Contract: Attendance Mutation

## Overview
The `AttendanceTakingCubit` provides methods to mutate student attendance status. These mutations must be atomic and handle state snapshots correctly to avoid race conditions.

## API Surface (Cubit)

### `markPresent({required AuthUser actor, required AttendanceRosterItem item})`
- **Purpose**: Marks a student as present in the current session.
- **Preconditions**: Session must be open (`session.isOpenAt(now)`).
- **Side Effects**: Sets `isMutating: true`, clears `mutationError`, calls repository, then updates state.

### `markLate({required AuthUser actor, required AttendanceRosterItem item})`
- **Purpose**: Marks a student as late.
- **Behavior**: Same as `markPresent`.

### `clearMark({required AuthUser actor, required AttendanceRosterItem item})`
- **Purpose**: Clears an existing attendance mark.
- **Behavior**: Same as `markPresent`.

## UI Integration Contract
- **Loading State**: UI must disable action buttons when `state.isMutating` is true.
- **Error Handling**: UI must display `state.mutationError` if non-null.
- **Data Integrity**: UI must always use `state.roster` for rendering, ensuring it matches the latest server state.
