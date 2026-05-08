# Student UI Refactor Plan

## 1. Objective
Refactor the student-related screens (List, Add/Edit, and Details) to match the "Ochre Sanctuary" design system defined in `DESIGN.md` and the provided HTML mockups. We will first extract common UI components to ensure maintainability, apply strict frontend design aesthetics, optimize for Flutter performance, and follow up with comprehensive reviews from specialized subagents.

## 2. Key Files & Scope
**Shared Components (New):**
*   `lib/core/widgets/cards/ochre_card.dart`
*   `lib/core/widgets/form/ochre_input_field.dart`
*   `lib/core/widgets/common/ochre_ambient_shadow.dart`

**Target Screens:**
*   `lib/features/student/presentation/screens/student_management_screen.dart`
*   `lib/features/student/presentation/screens/student_edit_screen.dart`
*   `lib/features/student/presentation/widgets/student_edit_form_sections.dart`
*   `lib/features/student/presentation/screens/student_detail_screen.dart`

## 3. Implementation Steps

### Step 1: Component Extraction & Theme Setup
*   Ensure `app_colors.dart` and `app_typography.dart` include Ochre Sanctuary tokens.
*   Create reusable `OchreCard` (with Level 1 ambient shadow), `OchreInputField` (with `surface_container_low` background and RTL icon support), and buttons.

### Step 2: Refactor Student List Screen
*   Implement the sticky header, search/filter row, and "Archive" toggle.
*   Redesign the `StudentCard` using the new `OchreCard` component.

### Step 3: Refactor Add/Edit Student Screen
*   Use the new `OchreInputField` components to build the Basic Info, Family Info, and Additional Info sections.
*   Implement floating sticky headers and action bars.

### Step 4: Refactor Student Profile Details
*   Implement the main profile header card, avatar, and Attendance Summary card with a circular progress indicator.

### Step 5: Subagent Reviews
*   **@frontend-specialist**: Review for aesthetic precision and "Ochre Sanctuary" compliance.
*   **@performance-optimizer**: Review the widget tree for rendering efficiency and `const` usage.
*   **@code-reviewer**: Review BLoC integration and Clean Architecture adherence.
