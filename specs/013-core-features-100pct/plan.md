# 013 — Core Features to 100%

## Objective
Bring **Authentication & Roles**, **Student Management**, **Attendance Sessions**, and **Attendance Recording** from their current ~55–60% completion to production-ready 100%. This plan is structured into four sequential phases — one per feature domain — each containing its own `plan.md`, `tasks.md`, `research.md`, and `data-model.md`.

## Constitution Alignment
- All business logic lives in Cubits/Blocs. Widgets are pure render+event.
- Firestore access only through Repository layer.
- Feature-first structure: `lib/features/<feature>/data|domain|presentation`.
- Every state/model class is immutable (`freezed` or `equatable`).
- All deps via `GetIt`. No direct construction in widgets.
- No God Widgets (>150 lines) or God Cubits (>200 lines).

## Phase Overview

| # | Phase | Current % | Target | Est. Hours | Spec Folder |
|---|-------|----------:|-------:|-----------:|-------------|
| 1 | Authentication & Roles | 55% | 100% | 16h | `phase-1-auth-roles/` |
| 2 | Student Management | 60% | 100% | 24h | `phase-2-student-management/` |
| 3 | Attendance Sessions | 60% | 100% | 20h | `phase-3-attendance-sessions/` |
| 4 | Attendance Recording | 55% | 100% | 24h | `phase-4-attendance-recording/` |

**Total**: ~84 hours

## Completion Gate (all phases)
1. `flutter analyze` returns 0 issues.
2. All widget/unit tests in scope pass (`flutter test`).
3. Visual match against `UI Screens/<screen>/screen.png`.
4. No overflow on 360dp width device.
5. Role access enforced end-to-end (admin / servant / student boundaries hold).

## Phase Execution Order
Phases 1 → 2 → 3 → 4. Auth must be live before student or attendance UX can be tested end-to-end.
