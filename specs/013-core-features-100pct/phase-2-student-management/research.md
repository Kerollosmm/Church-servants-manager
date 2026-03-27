# Phase 2 — Student Management: Research Notes

## R1 — Server-Side Name Search in Firestore
**Decision**: Use lexicographic range query: `name >= query && name <= query + '\uf8ff'` with `.orderBy('name').limit(pageSize)`.  
**Rationale**: Firestore does not support full-text search natively. Range queries work well for prefix search which covers the primary use case (searching by first name).  
**Limitation**: Case-sensitive. Mitigation: store a normalized `nameLower` field and query against that.  
**Alternative considered**: Algolia / Typesense — rejected, too heavy for current scope.  
**Index needed**: `nameLower ASC` (or `name ASC`) + optional `classId ASC`.

## R2 — Pagination Cursor Fix
**Decision**: Store `lastDocument: DocumentSnapshot?` in `StudentDataState`. On `StudentEventLoadMore`, use `.startAfterDocument(lastDocument)` for next page.  
**Rationale**: `startAfterDocument` is the idiomatic Firestore cursor and survives real-time updates. The `_hasReachedMax` flag is only set when the page returns fewer docs than `pageSize`.  
**Bug summary**: Current handler resets `lastDocument` on every stream event, causing reloads of page 1 each time.

## R3 — Student Self-View Pattern
**Decision**: `StudentHomeScreen` and `StudentProfileScreen` receive `AuthUser` from `RoleRouter.resolve()`. They use a dedicated `StudentProfileCubit` that fetches the student doc by `linkedUserId`.  
**Rationale**: Distinct cubit keeps self-view separated from admin management bloc.

## R4 — Form Reuse for Add/Edit
**Decision**: Single `StudentForm` widget accepting optional `StudentModel? initialData`. If null → add mode. `StudentEditScreen` wraps this and dispatches the right event.  
**Rationale**: Reduces duplication; constitution §III keeps logic in cubit/bloc.

## R5 — Archive vs Delete
**Decision**: Swipe-to-archive (soft-delete via `isArchived = true`). No hard delete from UI.  
**Rationale**: Existing use cases include `RestoreStudentUseCase` — confirms soft-delete architecture.
