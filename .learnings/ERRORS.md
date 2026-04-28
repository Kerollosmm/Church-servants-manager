# Errors Log

## [ERR-20260416-001] broken_import

**Logged**: 2026-04-16T17:30:00Z
**Priority**: high
**Status**: resolved
**Area**: config

### Summary
Refactoring led to a broken import in `lib/church_app.dart`.

### Error
```
error - Target of URI doesn't exist: 'package:church_management_system/features/auth/data/repos/firebase_auth_repository.dart' - lib\church_app.dart:8:8 - uri_does_not_exist
```

### Context
- Command: `flutter analyze`
- Task: Phase 4 BLoC refactoring.
- A path was assumed or an old path was left behind during an aggressive import reorganization.

### Suggested Fix
Always run `flutter analyze` immediately after refactoring and before concluding a task to catch broken imports or non-existent files.

### Metadata
- Reproducible: yes
- Related Files: lib/church_app.dart
- Resolution: Removed the invalid import.
