**Project Name:** Church Servant & Student Management System (CSMS)

**App Description:**
A mobile application for church servants (Sunday School teachers) and admins to manage student records, attendance, and team assignments efficiently. The app focuses on data integrity, offline capability, and a user-friendly experience for non-technical volunteers.

**Target Audience:**
- **Servants (Teachers):** Volunteers who need quick access to student info, contact details, and attendance tracking.
- **Admins (Head Servants):** Overseers who manage teams, assign servants, and oversee the entire ministry.

**Visual Style:**
- **Theme:** Modern, Clean, Trustworthy.
- **Primary Color:** Teal/Blue (Calm, Professional).
- **Secondary Color:** Orange/Amber (Warmth, Energy - for actions).
- **Typography:** Clear sans-serif (e.g., Inter or Roboto). High readability.
- **Components:** Material Design 3 influenced but with a custom, softer feel. Rounded corners (12px-16px).

**Key Screens to Design:**

1.  **Authentication:**
    -   **Login Screen:** Email/Password fields, "Forgot Password", clear "Login" button. Friendly welcome message.
    -   **Register/Sign Up:** Servant registration form (Name, Email, Phone, Role selection).

2.  **Dashboard (Home):**
    -   **Header:** Welcome message, User Profile picture, Notification bell.
    -   **Quick Stats:** Cards showing "Total Students", "My Team", "Upcoming Event".
    -   **Quick Actions:** "Add Student", "Take Attendance", "Manage Teams" (Admin only).
    -   **Recent Activity:** List of recent updates or birthdays.

3.  **Student Management:**
    -   **Student List:** Search bar at top. Filter dropdowns for "Year" and "Team". List items showing Student Name, Photo, Team Name, and actionable icons (Call, Message).
    -   **Student Profile (Detail):** Large photo, Name, Team badge. Tabs for "Info" (Contact, Address, School), "Attendance", "Notes".
    -   **Add/Edit Student:** Form with sections: Personal Info, Contact Info (Father/Mother mobile), Academic (School, Grade), Church Info (Confession Father, Team Assignment Dropdown).

4.  **Team Management (Admin Feature):**
    -   **Team List:** Tab bar for Groups (Year 1, Year 2, Year 3). List of Teams in each group.
    -   **Team Card:** Team Name, Servant Assigned (Avatar+Name), Number of Students.
    -   **Add Team Modal:** Input for Team Name.

5.  **Servant Management:**
    -   **Servant List:** List of all servants with their roles and assigned teams.
    -   **Assign Servant:** Interface to assign a servant to a specific Team/Group.

**Design Guidelines:**
-   Use a bottom navigation bar for main sections: Home, Students, Servants, Profile.
-   Ensure high contrast for text.
-   Use consistent iconography (Feather Icons or Material Symbols).
-   Input fields should have clear labels and validation states.
-   Buttons should distinguish between primary (filled) and secondary (outlined/ghost) actions.

**Full Design Spec (Build Guide for Figma):**

**Design System**
- **Grid & Spacing:** 4pt base grid. Screen padding 16. Section spacing 16-24. Card padding 16. List row height 72.
- **Corner Radius:** Cards 16, inputs 12, buttons 12, chips 999.
- **Elevation:** Level 0 (flat), Level 1 (cards), Level 2 (modals / FAB).

**Color Palette (Hex)**
- **Primary (Teal/Blue):** 
  - 700 `#0B4F57` 
  - 600 `#0F6E77` 
  - 500 `#138A8A` 
  - 400 `#27A3A1` 
  - 100 `#D6F2F1`
- **Secondary (Amber):** 
  - 600 `#C77600`
  - 500 `#E88C13`
  - 400 `#F0A53D`
  - 100 `#FFF0D6`
- **Neutrals:**
  - 900 `#0E1B1C`
  - 800 `#203033`
  - 700 `#3A4A4D`
  - 500 `#6B7A7D`
  - 300 `#B5C0C2`
  - 200 `#D7DEE0`
  - 100 `#EEF2F3`
  - 50 `#F7F9FA`
- **Semantic:**
  - Success `#2E7D32`
  - Warning `#ED6C02`
  - Error `#D32F2F`
  - Info `#0288D1`
- **Backgrounds:** 
  - App `#F7F9FA`
  - Surface `#FFFFFF`
  - Subtle Tint `#EAF5F5` (use sparingly for headers or cards)

**Typography**
- **Font Family:** Inter (fallback: Roboto).
- **Type Scale:**
  - Display 32/40, weight 700
  - H1 24/32, weight 700
  - H2 20/28, weight 600
  - H3 18/26, weight 600
  - Body 16/24, weight 400
  - Body Small 14/20, weight 400
  - Caption 12/16, weight 500

**Iconography**
- Use Material Symbols or Feather consistently (24px). Filled style for active states, outline for inactive.

**Components**
- **App Bar:** 56 height, title left, actions right. Use subtle tint on home.
- **Bottom Nav:** 4 items: Home, Students, Servants, Profile. Active pill indicator using Primary 500, icon+label.
- **Buttons:** Height 48. 
  - Primary: filled Primary 500, text white.
  - Secondary: outline Primary 500.
  - Ghost: text Primary 600, no border.
  - Destructive: outline Error.
- **Inputs:** Filled style with clear labels. Error text in Error color. Helper text 12/16.
- **Cards:** Elevation 1, radius 16, padding 16.
- **Chips/Filters:** Rounded pills with active fill Primary 100 and text Primary 700.
- **Tabs:** Segmented style with indicator pill.
- **Empty State:** Icon + short message + primary CTA.
- **Offline Banner:** Sticky top, Warning background, concise sync status.
- **Loading:** Skeleton cards and list rows.

**Motion**
- 150-250ms ease out for page transitions, subtle fade + slide up.
- Stagger list items by 30ms for dashboards and lists.

**Accessibility**
- Minimum touch target 44x44.
- Contrast ratio 4.5:1 for body text.
- Provide focus states for inputs and interactive elements.

**Screen-by-Screen Layouts**

**1) Login**
- Top: App logo + welcome message.
- Fields: Email, Password (with visibility toggle).
- Links: "Forgot password?" inline.
- Primary CTA: "Login".
- Secondary: "Create account".
- Background: soft gradient from `#EAF5F5` to `#FFFFFF`.

**2) Register**
- Form fields: Name, Email, Phone, Role (Servant, Admin - Invite Only).
- CTA: "Create account".
- Secondary: "Already have an account? Login".

**3) Dashboard (Home)**
- Header: Greeting ("Welcome back, [Name]"), avatar, notification bell.
- Quick Stats: 3 cards in a row (Total Students, My Team, Upcoming Event).
- Quick Actions: 3 large buttons (Add Student, Take Attendance, Manage Teams - admin only).
- Recent Activity: list rows with date and short context (birthdays, updates).

**4) Students List**
- Search bar with filter icon.
- Filter row: Year dropdown, Team dropdown.
- Student rows: avatar, name, team, call and message actions.

**5) Student Profile**
- Hero: Large photo, name, team badge.
- Quick actions row: Call, Message, Edit.
- Tabs: Info, Attendance, Notes.
  - Info: contact, address, school, parent contacts.
  - Attendance: mini chart + last 4 sessions.
  - Notes: list of teacher notes.

**6) Add / Edit Student**
- Multi-section form:
  - Personal: Name, DOB, Gender.
  - Contact: Father/Mother mobile, address.
  - Academic: School, Grade.
  - Church: Confession Father, Team assignment dropdown.
- Save button fixed bottom (sticky).

**7) Team Management (Admin)**
- Top tabs for Year 1/2/3.
- Team cards: Team name, servant avatar+name, student count.
- FAB or top-right button: "Add Team".
- Add Team modal: name field + save.

**8) Servant Management (Admin)**
- List of servants with role badge and assigned teams.
- Assign screen: dropdown for team and servant, confirm CTA.

**9) Attendance**
- Date selector + team selector.
- Student list with attendance toggles (Present, Absent, Late).
- Summary card at bottom.

**10) Profile / Settings**
- Profile card, role, contact info.
- Settings: Offline sync status, logout, change password.

**11) Notifications**
- List with time, type, and quick action (view, dismiss).
