
    1 # Comprehensive Multi-Agent Review Plan
    2
    3 **Goal:** Conduct a thorough, feature-by-feature review of the entire ChurchServers Management System (CSMS) using specialized subagents, ensuring alignment with product requirements,
      technical rigor, and code simplicity.
    4
    5 **Architecture & Context:** The review will strictly adhere to the CSMS `gemini.md` constraints: Clean Architecture, Offline-First (Hive -> Firestore), Custom Claims RBAC, Spark Plan
      budget limits (no Cloud Functions), and BLoC state management.
    6
    7 **Tech Stack:** Flutter, Dart, Firebase, Hive, BLoC.
    8
    9 ---
   10
   11 ### Task 1: Review Preparation
   12 - **Action:** Read the core architectural guidelines from `gemini.md` to ensure all agents share the same context.
   13 - **Action:** Identify all major feature modules: `admin`, `attendance`, `auth`, `servant`, `student`, `team`.
   14
   15 ### Task 2: Feature-by-Feature Multi-Agent Review
   16 For **each** feature module, the following sequence will be executed:
   17
   18 - [ ] **Step 2.1: Product & Requirements Review**
   19   - **Agents:** `@product-manager` & `@product-owner`
   20   - **Focus:** Analyze the feature's state against the requirements (offline-first, specific role matrix). Ensure all user needs and edge cases are covered. No technical advice
      provided.
   21
   22 - [ ] **Step 2.2: Technical & Logic Review**
   23   - **Agent:** `@code-reviewer`
   24   - **Focus:** Perform a deep technical review of the logic, identify code errors, verify implementation against Clean Architecture, run tests (aiming for 100% coverage), and perform
      code verification.
   25
   26 - [ ] **Step 2.3: Simplification & Quality Review**
   27   - **Agent:** `@code-simplifier` (coordinating with `@code-reviewer` if needed)
   28   - **Focus:** Locate over-engineered logic without removing necessary functionality. Verify adherence to Clean Code, Flutter, and Dart best practices (e.g., proper BLoC usage,
      avoiding unnecessary Firestore reads).
   29
   30 ### Task 3: Synthesis & Final Reporting
   31 - [ ] **Step 3.1: Compile Agent Findings**
   32   - **Agent:** Custom Agent (Gemini CLI Orchestrator)
   33   - **Focus:** Gather all responses from the subagents for all features.
   34
   35 - [ ] **Step 3.2: Verification**
   36   - **Agent:** Custom Agent (Gemini CLI Orchestrator)
   37   - **Focus:** Verify the agent findings against the codebase state and the project's strict guidelines (e.g., confirming no Cloud Functions were recommended).
   38
   39 - [ ] **Step 3.3: Generate Full Report**
   40   - **Action:** Output a final, consolidated markdown report detailing the state of the project, technical debt, coverage status, and actionable recommendations.