# Fix Plan: Church Management System

## Branch: openclaw-app-fixes

---

## Phase 1: Critical Fixes (Must fix before deploy)

### 1.1 Fix main.dart Syntax Errors
- [x] Move imports to top of file
- [x] Fix nested const issue in _StartupFailureApp
- [x] Fix padding const issue

### 1.2 Remove Generated File from Git
- [x] Add injection.config.dart to .gitignore

---

## Phase 2: High Priority Fixes

### 2.1 RoleUserRoute Missing Default Case
- [x] Add default case in role switch statement

### 2.2 AdminTeamService Atomicity
- [x] Make batch operations atomic (all-or-nothing)

### 2.3 StudentDataBloc Stream Refresh After Mutations
- [x] Refresh stream after create/update/delete operations

---

## Phase 3: Performance & Stability

### 3.1 Firestore Cache Limit
- [x] Set reasonable cache size (100MB instead of unlimited)

### 3.2 ServantDataRepository API Fix
- [x] Rename parameter or fix query logic

---

## Phase 4: Code Quality

### 4.1 Add const where possible
- [x] Optimize widget constructors

### 4.2 Add TODO comments for future work
- [x] Document known limitations

---

## Summary
- Total Issues Fixed: 10
- Files Modified: 5
- Status: READY FOR DEPLOYMENT
