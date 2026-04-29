---

## [ERR-20260429-001] inaccurate_documentation

**Logged**: 2026-04-29T18:40:00Z
**Priority**: low
**Status**: resolved
**Area**: documentation

### Summary
Failing to verify actual API signature before updating guidance in `SKILL.md`.

### Error
The `flutter-handling-concurrency/SKILL.md` file incorrectly stated that `Isolate.run()` requires a single-argument callback, leading to invalid code examples.

### Context
- Task: Fixing issues from PR #57 review.
- The review correctly identified that the documentation was out of sync with the actual Dart API (which takes a zero-arg closure).

### Suggested Fix
Always cross-reference internal documentation examples against the actual library source code or authoritative online API docs (api.dart.dev) before promoting patterns in a `SKILL.md` file.

### Metadata
- Reproducible: yes
- Related Files: .agents/skills/flutter-handling-concurrency/SKILL.md
- Resolution: Updated documentation to show `() => compute()` closure.

