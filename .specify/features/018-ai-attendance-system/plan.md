# Implementation Plan: AI-Enhanced Offline-First Attendance System

**Feature:** AI-Enhanced Offline-First Attendance System
**Spec:** [spec.md](./spec.md)
**Constitution:** [constitution.md](../../memory/constitution.md)
**Plan Version:** 1.0.0
**Created:** 2026-04-22

---

## Constitution Check

| Principle | Relevance | Compliance Strategy |
| --------- | --------- | ------------------- |
| P01: Clean Architecture | HIGH | AI features implemented as a vertical slice: presentation (chat/cards) -> domain (insight use cases) -> data (AI Logic service). |
| P02: SRP | HIGH | `AttendanceInsightService` handles AI prompting; `AttendanceSummaryService` handles aggregate calculations. |
| P03: No UI Logic | HIGH | All AI prompt construction and result parsing happens in domain/data layers. Widgets only display results. |
| P04: Auth Boundaries | CRITICAL | Cloud Functions validate caller role and student/group ownership before calling Gemini. |
| P05: Server-Auth Mutations | HIGH | `attendanceSummary` updates and `aiRecommendations` storage performed by Cloud Functions triggered on session close. |
| P11: Performance | MEDIUM | AI calls are asynchronous and don't block the UI thread. Cache results in `aiRecommendations` field. |
| P14: Firebase Safety | HIGH | Use transactions for updating aggregates to prevent races. Deploy new rules for `aiRecommendations` visibility. |
| P17: Future Agents | HIGH | Doc comments explain prompt templates and AI data reduction strategy (Aggregates vs Raw data). |

---

## Technical Context

### What Exists (Do NOT Rewrite)

| Component | Path | Status |
| --------- | ---- | ------ |
| Firestore Schema | `core/constants/` | Core collections (Users, Students, Sessions) are stable. |
| Auth System | `features/auth/` | Working. Custom claims used for roles. |
| Offline Cache | `core/sync/` | Hive-based caching logic is already implemented. |
| Connectivity Check | `core/utils/` | `connectivity_plus` integration exists. |
| Cloud Functions | `functions/src/` | Project initialized with TypeScript functions. |

### Unknowns (NEEDS CLARIFICATION)

- **AI Prompt Templates**: Need to define the exact prompt structures for "trend insights" and "student encouragement".
- **Trigger Logic**: Determine the best Cloud Function trigger (Firestore `onUpdate` for sessions vs. explicit `closeSession` callable).
- **Stitch Export Parity**: How closely Google Stitch generated CSS/HTML maps to our existing custom theme tokens.

---

## Phase 0: Outline & Research

### Research Tasks
1. **Research AI Prompt Safety** for church attendance context.
   - Task: Define minimal data subset for Gemini prompts to avoid PII exposure.
   - Outcome: `research.md` section on "Data Reduction Strategy".
2. **Research Firebase AI Logic Integration**.
   - Task: Verify Gemini free tier quotas and rate limits for Spark plan.
   - Outcome: `research.md` section on "AI Quota Management".
3. **Research Google Stitch to Flutter workflow**.
   - Task: Prototype one dashboard screen and evaluate translation effort to `lib/core/theme/`.
   - Outcome: `research.md` section on "Design-to-Code Mapping".

---

## Phase 1: Design & Contracts

### Data Model Changes (`data-model.md`)
- **Student Model**: Add `attendanceSummary` map (totalPresent, streak, etc.) and `aiRecommendations` subfield.
- **Servant/Team Model**: Add `groupAttendanceSummary` for aggregated insights.
- **Firestore Rules**: Update to allow students to read their own `aiRecommendations` and servants to read their group's summaries.

### Interface Contracts (`/contracts/`)
- **AI Service Interface**: `IAttendanceInsightService` with `getGroupInsight(groupId)` and `getStudentEncouragement(studentId)`.
- **Cloud Function Contract**: `getAttendanceInsight` callable (Request: {groupId, dateRange}, Response: {insightText, actions[]}).

---

## Phase 2: Implementation (Multi-Agent Orchestration)

To achieve the best results, we will use three specialized agents in parallel:

### Agent A: Backend Specialist (Firebase)
- **Workflow**: Create TypeScript Cloud Functions for AI logic.
- **Tasks**:
  1. Implement `onSessionClosed` trigger to calculate aggregates.
  2. Implement `getAttendanceInsight` callable using Firebase AI Logic + Gemini.
  3. Update `firestore.rules` and `firestore.indexes.json`.

### Agent B: Frontend Specialist (Flutter UI)
- **Workflow**: Build UI components based on Stitch prototypes.
- **Tasks**:
  1. Create `AttendanceInsightCard` widget.
  2. Implement `SmartQueryChatPanel` screen.
  3. Add `EncouragementHeader` to student home screen.
  4. Ensure all widgets follow `app_theme.dart` and P11 performance rules.

### Agent C: Domain & Sync Specialist (Core Logic)
- **Workflow**: Integrate AI service into Clean Architecture layers.
- **Tasks**:
  1. Define `AttendanceInsightRepository` and domain Use Cases.
  2. Update `AttendanceBloc` to handle AI insight states (loading, loaded, error).
  3. Implement offline fallback logic (hiding AI UI when `connectivity_plus` reports offline).

---

## Phase 3: Validation & DoD

- [ ] Unit tests for `AttendanceSummary` calculation logic.
- [ ] Integration tests for Cloud Function AI calls (using Emulator).
- [ ] UI verification against Stitch prototypes.
- [ ] Quota check: Ensure zero AI calls made while offline.
- [ ] Final `flutter analyze` and `dart format` pass.
