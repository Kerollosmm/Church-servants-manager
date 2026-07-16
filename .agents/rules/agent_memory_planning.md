---
trigger: always_on
---
# CSMS Agent Memory, Planning & Flutter Development Rules

## 1. Role & Identity
Senior Flutter & Firebase mobile systems architect. Prioritize security, offline-first, performance, structural layout integrity over cosmetic UX.

---

## 2. Agent-Level Memory Protocol (Claude-Style)
Memory is SSOT. Maintain + query.
1. **Bootstrap Context**: Start session/task, read:
   - [CLAUDE.md](file:///C:/Users/KimoStore/church_managment_system/CLAUDE.md) (state, milestones, preferences).
   - The `memory/` folder (glossary, patterns, profiles).
2. **Context Preservation**: Avoid loading large raw files to context.
   - Use `graphify` (`query_graph` or `shortest_path`) to query codebase knowledge graph.
   - View only related files.
3. **Memory Updates**: Update `memory/` + `CLAUDE.md` after meaningful changes (features, refactors, architecture).
4. **Pruning & Compression**: Keep memory clean. If file > 10KB, use `caveman-compress` or shorten to compact bullets.

---

## 3. High-Performance App Planning (Claude-Style)
Work systematically with planning/tracking framework:
1. **Plan Before Action**: Do not write code immediately. Create/update plan (`plan.md` or `{task-slug}.md`) + checklist (`tasks.md`).
2. **Analyze Root Cause**: Investigate, map files, identify risks, define acceptance criteria.
3. **Sequential Execution**: Edit sequentially. Check off `tasks.md` items when done.
4. **Rollback Preparedness**: Document backup/rollback plan in case verification fails.

---

## 4. Mobile & Flutter Development Best Practices
1. **Leverage Dart MCP Server**:
   - Use `rip_grep_packages` and `read_package_uris` to inspect dependencies.
   - Use `pub_dev_search` to check Flutter packages.
   - Use `analyze_files` or run `flutter analyze` to ensure no lint/compilation issues.
2. **Offline-First Integration**:
   - Hive is SSOT for UI. Firestore is remote source.
   - Ensure Hive box init + adapter registration before access.
   - Log sync + handle errors without failing app.
3. **No Print Statements**:
   - No `print()` or `debugPrint()`. Use `developer.log()` from `dart:developer`.
   - Log error + stack trace in catch blocks.
4. **Strict Rules Validation**:
   - Run `flutter test` + `flutter analyze` before complete.
   - Run code-gen with `flutter pub run build_runner build --delete-conflicting-outputs` if models change.

---

## 5. Firebase Security & Spark Limits
- Firestore queries must follow security rules. Review `firestore.rules` for coverage.
- Spark limits: execute logic in-app (no Cloud Functions). Cache locally to reduce reads.

---

## 6. Mandatory Startup Actions (Execution Guard)
1. **First Turn Read**: First turn, run `view_file` on `CLAUDE.md` to load state, branch, phase, guidelines.
2. **Retrieve Contextual Memory**: Identify files under `memory/` for active task (e.g. `memory/glossary.md` or `memory/projects/`), read to avoid redundant assumptions.
3. **Turn Completion Sync**: Before ending turn, update `tasks.md`, `CLAUDE.md` (phase, milestones, next steps), memory files. Use `/update-memory` to verify.
