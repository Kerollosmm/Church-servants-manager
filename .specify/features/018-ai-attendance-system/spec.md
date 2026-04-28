# Feature Specification: AI-Enhanced Offline-First Attendance System

**Feature:** AI-Enhanced Offline-First Attendance System
**Short Name:** ai-attendance-system
**Created:** 2026-04-22
**Status:** Draft
**Author:** Gemini CLI

---

## Clarifications

### Session 2026-04-22
- Q: How frequently should the denormalized attendanceSummary be updated in Firestore? → A: Update only when a servant "closes" an attendance session (Session-end policy).
- Q: Who should be able to view student-specific AI insights/encouragement messages? → A: Both the authenticated Student (for their own data) and their assigned Servants (to facilitate proactive care).
- Q: What level of student detail should be included in the AI prompt for group trend analysis? → A: Aggregated metrics only (counts, percentages, streaks, and trend deltas) to ensure privacy and token efficiency.

---

## 1. Problem Statement
The current Church Servants Management System (CSMS) handles core attendance well but lacks advanced insights and proactive student engagement. Servants must manually analyze trends to identify dropping attendance or absent students across weeks. Students have limited visibility into their own patterns and receive no encouragement or explanations for their attendance history. Additionally, designing new UI flows for these features can be slow and disconnected from the existing architecture.

---

## 2. Business Goal
Integrate optional, read-oriented AI capabilities into the existing Flutter + Firebase architecture to:
1. Provide servants with natural language insights into attendance trends.
2. Enable a smart query assistant for servants to quickly find specific groups of students (e.g., "absent for 3 weeks").
3. Give students AI-generated explanations and encouragement messages based on their personal attendance data.
4. Accelerate product design using Google Stitch while maintaining architectural alignment.
5. Maintain Spark (Free Tier) compliance by optimizing AI calls and Firestore operations.

---

## 3. User Value
| Actor    | Value Delivered                                                |
| -------- | ------------------------------------------------------------- |
| Servant  | Instant answers to complex trend questions without manual analysis |
| Servant  | Fast identification of at-risk students via natural language queries |
| Student  | Personalized encouragement and clarity on attendance history   |
| Church   | Proactive care for students based on data-driven AI insights   |
| Admin    | Rapid prototyping and design iteration with Google Stitch     |

---

## 4. Actors and Roles
### 4.1 Servant/Admin
- Can ask natural language questions about group attendance.
- Can use the smart query assistant to filter students.
- Can view AI-generated action suggestions (e.g., "Reach out to student X").
- Can view AI-generated insights and encouragement messages for students assigned to their group(s).

### 4.2 Student
- Can view personal AI-generated insights and encouragement messages.

### 4.3 System (Backend)
- Uses Firebase AI Logic + Gemini to generate insights.
- Updates denormalized `attendanceSummary` fields when a session is closed.

---

## 5. Scope
### 5.1 In Scope
- Natural language insights for group attendance patterns based on aggregated metrics.
- Smart query assistant for servants using Cloud Functions over Firestore.
- Personal AI encouragement messages for students.
- Denormalized `attendanceSummary` fields on `students` and `servants` documents.
- Integration with Firebase AI Logic and Gemini Developer API (Free Tier).
- UI prototyping using Google Stitch.

### 5.2 Out of Scope
- On-device AI models (online only).
- AI-driven attendance marking (still manual).
- Advanced multi-agent workflows (unless using Genkit).
- High-volume write-oriented AI features.
- Sending raw student names or PII in AI prompts for trend analysis.

---

## 6. User Stories
### US-01: Servant — Get Trend Insight
As a servant, I want to ask "Why is Group B's attendance dropping?" so I can understand the underlying patterns.

### US-02: Servant — Smart Query
As a servant, I want to ask "Show absent students in the last 3 weeks for Grade 5" so I can quickly identify who to contact.

### US-03: Student — Get Encouragement
As a student, I want to see a message like "You've been consistent for 4 weeks, keep it up!" to feel motivated.

### US-04: Servant — Suggested Actions
As a servant, I want the AI to suggest actions like "Student X has missed 3 sessions, consider a phone call" so I can take proactive care.

---

## 7. Functional Requirements
### FR-01: AI Insight Generation
Call `getAttendanceInsight` Cloud Function with parameters like `groupId`, `dateRange`, and `question`. Prompts use aggregated group data only.

### FR-02: Smart Query Assistant
Provide a chat-like interface that translates natural language into Firestore queries executed via Cloud Functions.

### FR-03: Denormalized Aggregates
Automatically update `attendanceSummary` (totalPresent, totalAbsentLast30Days, streak) on `students`/`servants` docs when a servant marks an attendance session as "closed".

### FR-04: AI-Ready Data Model
Add `aiRecommendations` subfield to store the latest generated suggestions to minimize repeated AI calls.

### FR-05: Offline Fallback
Hide AI prompts or show a "Connect to the internet to use AI" message when offline.

### FR-06: Stitch Prototyping
Use Google Stitch to generate UI mockups for dashboards, AI chat interfaces, and conflict resolution screens.

---

## 8. Non-Functional Requirements
### NFR-01: Performance
AI insights should return within 5 seconds under normal network conditions.

### NFR-02: Cost Optimization
Maintain total Firestore reads and writes within the Spark plan limits (50,000 reads/day, 40,000 writes/day) by using a session-end update policy for aggregates.

### NFR-03: Security
AI prompts must use minimal necessary aggregated data; sensitive notes or raw PII should not be sent to the AI unless strictly required.

### NFR-04: Privacy
Student-specific AI messages must only be visible to the authenticated student and their assigned servants.

---

## 9. Business Rules
### BR-01: AI Availability
AI features are strictly online-only and must not block the core attendance flow if unavailable.

### BR-02: Aggregate Primacy
AI prompts should prioritize using denormalized `attendanceSummary` data to minimize Firestore reads.

---

## 16. Key Entities
- **Users / Servants / Students**: Existing identity and role entities.
- **AttendanceSessions / AttendanceRecords**: Existing core data.
- **attendanceSummary**: New object on `students` and `servants` documents for aggregated metrics.
- **aiRecommendations**: Optional subfield for the latest generated suggestions.

---

## 17. Assumptions
- **Gemini Free Tier**: The project will use the Gemini Developer API free tier via Firebase AI Logic.
- **Spark Plan**: Current usage levels will remain within Firebase Spark plan quotas.
- **Architecture**: AI will be implemented as a stateless service layer over existing data.

---

## 20. Success Criteria
- Servants receive AI-generated insights within 5 seconds of the request.
- Zero app crashes or blocked flows when the device is offline or AI quota is reached.
- Total Firestore write overhead for AI-related aggregates is less than 5% of core attendance writes.
- UI design iteration speed for new features is noticeably faster using Google Stitch.
