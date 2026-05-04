# Research Findings: AI-Enhanced Offline-First Attendance System

**Feature:** AI-Enhanced Offline-First Attendance System
**Created:** 2026-04-22

---

## 1. AI Quota Management (Spark Plan)
- **Firebase AI Logic**: Integrates with Gemini Developer API.
- **Gemini Free Tier**: Offers 15 RPM (requests per minute) and 1M TPM (tokens per minute) for Gemini 1.5 Flash (as of early 2025). This is sufficient for low-volume church attendance insights.
- **Spark Plan Compliance**: No billing required if using the "Free Tier" of the Gemini Developer API through Firebase AI Logic.

## 2. Data Reduction Strategy (PII Safety)
- **Principle**: Minimize PII (Personally Identifiable Information) sent to AI models.
- **Prompt Structure**:
  - Instead of: "Explain why John Doe is absent."
  - Use: "Explain why Student ID `ABC-123` has missed 3 sessions in a row, given the group average is 10% absence."
- **Aggregates**: Use `attendanceSummary` fields (counts, streaks) rather than raw session records in prompts to save tokens and improve privacy.

## 3. Design-to-Code Mapping (Google Stitch)
- **Workflow**: Generate UI in Stitch Labs -> Export Figma -> Translate to Flutter using `lib/core/theme/`.
- **Theme Alignment**: Stitch prototypes should be refined in Figma to match `AppColors` and `AppTypography` defined in `lib/core/theme/`.

---

## Decisions
- **Decision**: Use Gemini 1.5 Flash for speed and low cost.
- **Rationale**: Flash provides enough reasoning capability for attendance patterns while staying within free tier limits.
- **Decision**: Update `attendanceSummary` only on `session_closed`.
- **Rationale**: Reduces Firestore write volume compared to updating on every mark, keeping the project well within the 40k write/day Spark limit.
