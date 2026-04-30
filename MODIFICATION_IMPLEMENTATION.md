# P0: Hive-First Sync & Cost Optimization Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the app into a true offline-first system and eliminate "Quota Killer" Firestore/AI patterns.

---

### Phase 1: Global Data Modeling
- [ ] **Task 1.1: Add SyncStatus Enum**
- [ ] **Task 1.2: Update Models** (Attendance, Team, Student, Servant) with `syncStatus` and `updatedAt`.
- [ ] **Task 1.3: Create AI Cache Model**
Create `AiCacheEntry` with `queryHash`, `response`, and `expiry` for Hive.
- [ ] **Task 1.4: Generate Adapters**

---

### Phase 2: Hive & Quota Foundation
- [ ] **Task 2.1: Initialize Hive Boxes**
Open: `marks`, `sessions`, `teams`, `students`, `servants`, `ai_cache`.
- [ ] **Task 2.2: Implement LocalSources**
- [ ] **Task 2.3: Implement AI Caching Logic**
Update `StudentAIService` to check `ai_cache` box before calling Gemini.

---

### Phase 3: Repository Refactor (The Cost Fix)
- [ ] **Task 3.1: AttendanceRepository: Bounding & Consolidation**
    - Apply `.limit(50)` to `watchSessionsForTeam`.
    - Delegate `getStudentAttendanceStats` to `getStudentAttendanceHistory` to save 1 `collectionGroup` read.
- [ ] **Task 3.2: AttendanceRepository: Validation Optimization**
    - Refactor `_writeMark` to remove the 2 Firestore reads per mark. Write to Hive immediately.
- [ ] **Task 3.3: StudentQueryService: Cache-First**
    - Ensure `getStudentsByClass` uses `Source.serverAndCache`.

---

### Phase 4: Sync Engine & Admin Fixes
- [ ] **Task 4.1: SyncService Worker**
    - Batch push (400) + Exponential backoff.
- [ ] **Task 4.2: Servant Archiving**
    - Refactor `AdminAuthClient` to use client-side `isActive` flag updates.

---

### Phase 5: Verification & Stress Testing
- [ ] **Task 5.1: Quota Audit**
Verify Firestore usage for 30 marks = 1 batch write (instead of 60 reads).
- [ ] **Task 5.2: Offline Marking Test**
- [ ] **Task 5.3: AI TTL Verification**

---

## Journal
- **2026-04-28:** Integrated CodeRabbit Cost Optimization report. Added tasks for stream bounding, AI caching, and query consolidation.
