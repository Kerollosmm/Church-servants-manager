# Phase 2 — Student Management: Data Model

## StudentModel (existing — reference only)
```
StudentModel {
  docID: String            // Firestore document ID
  name: String
  classId: String          // teamId
  phone: String?
  parentPhone: String?
  linkedUserId: String?    // Firebase Auth UID if student has login
  isArchived: bool
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

## StudentEditArgs (existing RouteArgs)
```
StudentEditArgs {
  studentId: String?       // null = add mode
  initialData: StudentModel?
}
```

## StudentDetailArgs (existing RouteArgs)
```
StudentDetailArgs {
  studentId: String
  student: StudentModel
}
```

## StudentDataState shape (reference for UI consumers)
```
StudentDataState {
  students: List<StudentModel>       // current page accumulation
  status: StudentDataStatus          // initial | loading | success | failure
  hasReachedMax: bool
  searchQuery: String
  errorMessage: String?
  lastDocument: DocumentSnapshot?    // cursor for next page
}
```

## Firestore Index Required (new — for server-side search)
**Collection**: `Students`  
**Fields**:
1. `name` ASC
2. `classId` ASC (composite for team-scoped search)
3. `isArchived` ASC

Add to `firestore.indexes.json`.

## Student Collection Path
`Students/{studentId}` — capital **S** (existing production schema).
