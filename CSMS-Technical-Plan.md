Church Servants Management System (CSMS) 

Unified Technical Plan: Results \+ Attendance 

Version: 1.0 

Date: December 27, 2025 

Prepared for: Church Leadership \+ Development Team 

Timeline: 20–26 weeks (5–6 months) | Non-rushed, quality-focused 

Status: Ready for Implementation 

Executive Summary 

Transform two separate, fragmented systems into one unified, offline-first, secure mobile app with a scalable backend. This comprehensive plan addresses critical security gaps, distribution challenges, and system reliability issues while establishing a foundation for sustainable growth. 

Current State: Two separate projects, significant security gaps, manual distribution nightmare 

Target State: One unified, offline-first, secure mobile app with scalable Firebase backend Investment Required: Technical expertise \+ Firebase free tier ($0–$300/month at scale) Expected Timeline: 20–26 weeks (5–6 months), non-rushed, quality-focused development 

Part 1: Critical Problems Analysis 

1.1 Security Vulnerabilities 

Problem 1: Student Results Exposed ( CRITICAL)

Current Implementation Issues: 

No authentication required—users enter ID number only 

Anyone can guess colleague's ID and access their grades 

No audit trail—impossible to determine who accessed what data 

Complete absence of access controls 

Real-World Impact: 

Student privacy violations 

Cannot prove data integrity 

Violates church data governance requirements 

Potential legal and organizational liability 

Proposed Solution: 

Username \+ Password authentication with JWT-based sessions, role-based access control,   
and comprehensive audit logging for all data access. 

Problem 2: Attendance Single Points of Failure ( HIGH) 

Current Implementation Issues: 

Only one administrator can mark attendance 

System failure if primary admin is absent 

No distributed access control mechanism 

Operational bottleneck affecting service execution 

Real-World Impact: 

Service disruption risk 

Unfair dependency on single individual 

Inability to scale to additional servants 

System paralysis during personnel absence 

Proposed Solution: 

Role-based access control enabling multiple servants to mark attendance, distributed system architecture, and scalable permission management. 

Problem 3: Manual Distribution Process ( HIGH) 

Current Implementation Issues: 

Android APK distributed manually to each device 

Every application update requires manual redistribution 

Version fragmentation across installed instances 

Silent update failures with no visibility 

Real-World Impact: 

Features unavailable on outdated versions 

Security patches fail to reach all devices 

Significant time investment in manual distribution 

Uncontrolled application state across deployment 

Proposed Solution: 

Google Play Store automatic distribution with Firebase Remote Config for progressive feature rollout and automatic security patching. 

Problem 4: Offline Functionality Failure ( HIGH)

Current Implementation Issues: 

Mobile application requires stable network connectivity 

Church WiFi infrastructure is unstable 

Attendance data lost when connection drops 

No offline caching or synchronization mechanism 

Real-World Impact:   
Data loss during service hours 

User frustration and reduced adoption 

Unreliable system during critical church services 

Incomplete attendance records 

Proposed Solution: 

Offline-first architecture with local Hive storage, automatic synchronization when connectivity restored, and conflict resolution mechanisms. 

1.2 Architectural Deficiencies 

| Architectural Problem | Current  State | Impact  | Solution |
| :---- | ----- | ----- | ----- |
| No unified data model | Two  separate  databases | Manual sync  nightmare | Firestore as single source of truth |
| No session  management | Stateless ID lookup only | Security  vulnerability | JWT \+ Firebase Auth |
| No role-based access | Admin vs  user unclear | Permission  creep | Firestore Security Rules \+ role matrix |
| No sync  strategy | No offline  support | Data loss | Hive (local) \+  Firestore (cloud) |
| No error  handling | App crashes silently | Unknown  system failures | Comprehensive  error handling \+  reporting |
| No analytics | Cannot track usage  patterns | Blind  deployment  decisions | Firebase Analytics built-in |

Table 1: Architectural Problems Matrix 

Part 2: Proposed System Architecture 

2.1 High-Level System Design

The proposed unified architecture consolidates all functionality into a single, cohesive system with clear separation of concerns across frontend, backend, and integration layers. 

Frontend Layer (Mobile Application) 

Results Module: Display all terms with historical context 

Attendance Module: Manual marking, barcode scanning, Face ID ready Admin Dashboard: Comprehensive reporting and user management 

Offline-First Architecture: Hive-based local storage with automatic synchronization   
Backend Layer (Firebase \+ Cloud Services) 

Authentication: Firebase Auth with role-based access control 

Database: Firestore with granular security rules 

Business Logic: Cloud Functions for complex operations 

Storage: Firestore and Cloud Storage for documents and images 

Real-Time Updates: Firestore listeners for automatic UI synchronization External Integrations 

Google Play Store: Automated application distribution 

Google Play App Signing: Security infrastructure 

Firebase Crashlytics: Production monitoring and error tracking 

2.2 Core System Modules 

Module 1: Authentication & User Management 

Responsibility: Secure authentication, role-based access control, and session management Key Components: 

Firebase Authentication (email/password provider) 

Custom JWT tokens for stateless API operations 

Servant profiles with comprehensive metadata 

Role matrix: Admin, Servant, Teacher, Viewer 

Authentication Flow: 

1\. Servant enters username and password 

2\. Firebase validates credentials 

3\. JWT token issued with embedded role and permissions 

4\. Token stored securely locally using flutter\_secure\_storage 

5\. All subsequent requests include JWT in headers 

6\. Server validates JWT before responding 

Security Implementation: 

Passwords hashed using bcrypt (Firebase default) 

JWT expires every 24 hours with refresh token strategy 

Passwords never stored locally—only secure tokens 

All sensitive data encrypted at rest 

Token rotation on logout 

Module 2: Results Management System

Current Problem: Single term visibility, no historical context, no access controls Proposed Design: Multi-term history, visual timeline, per-servant access control 

System Components: 

Results repository backed by Firestore 

UI layer with timeline, term selector, and filters 

Admin panel for results upload and management   
Audit logs tracking all access events 

User Workflow: 

1\. Servant opens application and views results tab 

2\. App checks local Hive cache for instant display 

3\. If online, app fetches latest from Firestore and merges 

4\. Servant selects specific term to view all scores and average 

5\. Swipe functionality reveals previous terms 

6\. Admin publishes new results triggering automatic sync to all devices Access Control Model: 

Each servant can view only their own results 

Admin users can upload and manage all results 

All data access logged for audit trail 

Role-based permissions enforced at Firestore level 

Module 3: Attendance Management System

Current Problem: Single admin bottleneck, complex Face ID requirements, distribution nightmare 

Proposed Design: Offline-first operation, multi-servant capability, progressive feature complexity 

Progressive Implementation Phases: 

Phase 1 (v1.0): Manual selection \+ Barcode scanning ✅ 

Phase 2 (v1.5): Optional Face ID (pending model training) 

Phase 3 (future): Hybrid approach (Face ID primary with manual fallback) System Components: 

Attendance service backed by Firestore 

UI for servant list management and quick marking 

Barcode scanner integration with offline capability 

Admin reporting with attendance trends and export 

Offline synchronization mechanism for background sync 

Operational Workflow (Phase 1 \- Manual \+ Barcode): 

At Home (Preparation Phase): 

Admin opens application and selects today's service 

Offline mode loads servant list from local Hive storage 

App prepares for connectivity-independent operation 

At Church (Service Execution): 

Multiple servants can open application simultaneously 

No single admin bottleneck—distributed responsibility 

Instant feedback on all attendance actions 

Manual Attendance Marking:   
Servant opens application and views alphabetical servant list Tap servant name to mark present/absent/late 

Local Hive updates immediately (instant visual feedback) No network required for marking operation 

Barcode Scanning: 

Servant activates barcode scanner from UI 

Scans servant's ID card barcode 

System performs offline local ID lookup 

Automatically marks servant present 

100% offline capability—no WiFi required 

Synchronization Phase (When Online): 

Background sync manager detects connectivity 

All local Hive records compared with Firestore 

Changes uploaded to server 

Firestore audit trail updated 

User notified of successful sync 

Conflict Resolution: 

If two devices mark same servant differently 

"Last-write-wins" algorithm with manual override option Admin access to conflict resolution UI 

Ability to reconcile discrepancies in report view 

Access Control Implementation: 

Multiple servants can mark attendance 

Admin has view access to all records 

Role-based permissions enforced at service level 

Audit trail logs: who marked what, when, from which device 

Module 4: Admin Dashboard

Core Responsibilities: 

User account creation and management 

Results upload and publishing 

Attendance reporting and analysis 

Sync status monitoring 

Audit log access and review 

Key Features: 

CSV import for batch results upload 

Alternative manual entry interface 

Preview functionality before publishing results 

Real-time servant and user management 

Cross-device sync status visibility 

Comprehensive export to PDF/CSV formats 

System health monitoring and error tracking   
2.3 Data Communication Flows 

Flow 1: Servant Login Process 

1\. App displays login screen (works offline) 

2\. Servant enters username and password 

3\. If online: App communicates with Firebase Auth 4\. Firebase Auth validates credentials and returns tokens 5\. App stores idToken and refreshToken in secure storage 6\. App navigates to home screen 

7\. Background synchronization begins automatically 

Flow 2: Viewing Results History 

1\. Servant opens Results tab 

2\. App loads terms from local Hive cache (instant) 3\. If online, app performs background operation: 

Query Firestore for results/{servantId}/terms 

Firestore applies permission checks 

App merges remote and local data 

Hive cache updated with fresh data 

4\. UI renders timeline visualization (newest to oldest) 5\. Real-time listener maintains sync with Firestore changes 

Flow 3: Attendance Marking & Synchronization Church Service (Offline Operation): 

1\. Servant opens Attendance tab 

2\. App loads servant list from local Hive (instant) 3\. Servant taps name to mark present 

4\. Local Hive updates immediately 

5\. UI displays checkmark confirmation (instant feedback) Later (When Connectivity Restored): 

1\. Sync manager detects internet connection 

2\. App compares local Hive with Firestore 

3\. Firestore processes updates and logs to audit trail 4\. Local Hive marked records as synced 

5\. User receives notification "Attendance synced ✓" 

Flow 4: Admin Results Publication

1\. Admin opens Results Management page 

2\. Admin selects CSV file or enters data manually 

3\. Admin reviews preview (all servants and scores) 4\. Admin clicks Publish Term button 

5\. App invokes Cloud Function for validation 

6\. Cloud Function writes to Firestore: results/{servantId}/... 7\. Firestore real-time listeners trigger on all connected apps 8\. Each servant's app updates local Hive cache automatically 9\. Servants receive notification "New results available"   
Part 3: Technology Stack Justification 

| Component  | Technology  | Rationale  | Alternative |
| ----- | ----- | ----- | ----- |
| Frontend  | Flutter | Single  codebase  iOS+Android | React Native |
| Mobile  Storage | Hive | Offline-first, no SQL | SQLite,  Realm |
| Backend DB  | Firestore | Real-time,  offline, rules | Firebase RT DB |
| Authentication Firebase Auth |  | Stateless,  secure | JWT custom, Auth0 |
| Real-time Sync Firestore |  | Automatic,  conflict-free | REST polling |
| Distribution  | Google Play | Auto  updates,  security | APK manual |
| Barcode  Scanning | flutter\_barcode\_scanner | Simple,  reliable | google\_mlkit |
| Local  Encryption | flutter\_secure\_storage | Secure  tokens | Shared  preferences |
| Monitoring  | Firebase Crashlytics | Automatic  tracking | Sentry,  DataDog |

W 

R 

T 

m 

p 

S 

m 

B 

s 

F 

i 

B 

p 

P 

p 

P 

r 

T 

p 

F 

i 

Table 2: Technology Stack Decision Matrix 

Part 4: Unified System Architecture Rationale Why Consolidate into Single Application?

| Aspect  | Single Unified App  | Two Separate Apps |
| ----- | :---- | :---- |
| User Experience | Results \+ attendance  accessible in one app | Context loss switching between apps |
| Offline Sync | One sync engine, single source of truth | Two separate sync  mechanisms \= conflicts |
| Application  Updates | One APK to maintain and distribute | Two APKs \= version  fragmentation |
| Data Consistency | One database, unified schema | Manual sync between two systems |
| Permission  Model | Granular per-feature access | App-level all-or-nothing permissions |
| Development  Efficiency | Shared authentication, storage, sync | Duplicate code,  maintenance burden |
| Deployment | Single Google Play  deployment | Two separate  deployments |

Table 3: Single vs. Dual Application Architecture Comparison 

Strategic Recommendation: Unified Single Application 

Rationale: 

Servants are identical users requiring both results and attendance functionality Synchronization complexity increases exponentially with multiple systems Distribution becomes trivial with single Play Store submission 

Future enhancements (notifications, analytics) require both modules integrated 

Part 5: Implementation Roadmap (20–26 Weeks) 

Phase 1: Foundation & Security (Weeks 1–8)

Strategic Goal: Establish secure authentication, offline-first capability, and data migration infrastructure 

Phase Deliverables: 

✅ Secure login operational (online and offline) 

✅ Local storage with sync engine functional 

✅ Legacy data migrated to Firestore 

✅ Comprehensive test coverage for auth and sync 

Week-by-Week Execution: 

Week 1: Firebase Project Setup 

Create Firebase project (console.firebase.google.com) 

Enable Authentication, Firestore, Cloud Storage, Cloud Functions   
Configure Firestore security rules (no public access) 

Establish service accounts for administrative scripts 

Weeks 1–2: Flutter Project Initialization 

Create Flutter project with clean architecture 

Add core dependencies (Firebase, Hive, connectivity, secure storage) Establish folder structure for scalability and maintainability Configure Firebase initialization in application 

Weeks 2–4: Authentication Module Development 

Firebase Auth setup (email/password provider) 

Servant data model: {id, email, username, name, role, department} Login use case and repository implementation 

Secure token storage using flutter\_secure\_storage 

Logout and session expiry mechanisms 

Unit tests for authentication flows and edge cases 

Weeks 3–4: Local Storage Implementation 

Initialize Hive boxes for servants, results, attendance, sync\_meta Implement encryption at rest for sensitive data 

Create migration logic for legacy data format 

Define data persistence strategy on logout 

Weeks 4–5: Firestore Schema & Security 

Design and implement Firestore collections: 

servants/ \- user profiles and role assignments 

results/ \- per-servant term history 

attendance/ \- per-service attendance records 

audit\_logs/ \- complete action audit trail 

Configure security rules (role-based access) 

Create indexes for efficient querying 

Weeks 5–6: Data Migration Planning 

Extract data from existing applications 

Transform legacy data to new Firestore schema 

Develop one-time migration script 

Implement validation and checksum verification 

Weeks 6–8: Sync Engine Core Development 

Implement offline/online detection 

Establish Hive as source of truth during offline 

Create background sync job for online mode: 

Differential local vs. Firestore comparison 

Upload local changes 

Download remote updates 

Conflict resolution (last-write-wins \+ manual override) 

Write integration tests for sync scenarios  
Weeks 7–8: Error Handling & Production Monitoring 

Establish custom exception hierarchy 

Integrate Firebase Crashlytics 

Implement user-facing error dialogs 

Configure debug logging (production-safe) 

Phase 2: Core Features (Weeks 9–18) 

2A: Results Module (Weeks 9–12)

Strategic Goal: Implement multi-term results viewing with full offline support Phase Deliverables: 

✅ Servants view complete term history 

✅ 100% offline functionality 

✅ Automatic online synchronization 

✅ Visual timeline and filtering 

✅ Comprehensive test coverage 

Development Timeline: 

Week 9: Results Repository & Use Cases 

GetAllTermsUseCase: Load all terms (from Hive offline, Firestore online) GetTermDetailsUseCase: Retrieve complete term with all scores CacheResultsUseCase: Manage local cache updates 

Implement offline merge logic 

Weeks 10–11: Results UI Implementation 

Results list page (all terms, newest first) 

Term detail page (subjects, scores, averages) 

Timeline visualization (score trends over time) 

Search and filter functionality by term name 

Accessibility features (dark mode, large text, RTL Arabic) 

Week 11: State Management (BLoC) 

BLoC setup: Loading / Loaded / Error states 

Event handling: FetchTerms / SelectTerm / RefreshResults 

Real-time Firestore listeners for automatic UI updates 

Week 12: Testing & Integration 

Unit tests: repository merge logic, use cases 

Widget tests: results list rendering, date sorting 

Integration tests: offline to online transition   
2B: Attendance Module \- Phase 1 (Weeks 13–18)

Strategic Goal: Multi-servant attendance with barcode scanning, 100% offline Phase Deliverables: 

✅ Multiple servants mark attendance (not just admin) 

✅ Manual \+ barcode scanning operational 

✅ 100% offline (no WiFi required) 

✅ Automatic online synchronization 

✅ Comprehensive test coverage 

Development Timeline: 

Week 13: Attendance Repository & Use Cases 

GetTodayServantListUseCase: Retrieve service attendees 

MarkPresentUseCase: Instant local update 

GetAttendanceRecordsUseCase: Historical retrieval 

Conflict resolution logic implementation 

Weeks 13–14: Barcode Scanner Integration 

flutter\_barcode\_scanner setup 

Barcode format definition (Servant ID card number) 

Offline local ID lookup mechanism 

Barcode validation (check digit, length) 

Error handling (invalid barcodes, missing servants) 

Weeks 14–15: Manual Attendance UI 

Service type selector (Morning / Afternoon / Special) 

Alphabetical servant list with search/filter 

Mark present/absent/late interface 

Visual feedback (color changes, checkmarks) 

Quick actions (Mark All Present, Clear All) 

Weeks 15–16: Barcode Scanner UI 

Scanner activation button 

Real-time scan feedback 

Automatic marking after successful scan 

Sound notification (optional) 

Weeks 16–17: Offline Sync Implementation 

Mark attendance locally (instant Hive update) 

Background sync when connectivity restored 

Conflict resolution (two devices marking differently) 

Audit trail (who marked, when, from which device) 

Week 17: Attendance Reporting 

Date range attendance viewing 

CSV export functionality   
Per-servant attendance rate calculation (%) 

Trends visualization 

Week 18: Testing & Integration 

Unit tests: barcode parsing, conflict resolution 

Widget tests: servant list, marking UI 

Integration tests: offline marking to online sync 

Phase 3: Admin Features & Production Deployment (Weeks 19–22)Strategic Goal: Admin dashboard, results publication, Google Play launch Phase Deliverables: 

✅ Admin results upload and user management 

✅ App on Google Play (automatic user updates) 

✅ Reports and export functionality 

✅ Production monitoring enabled 

Development Timeline: 

Week 19: Admin Permissions & Role Implementation 

Firestore security rules for admin-only operations 

Admin role flags in servant profiles 

Admin-only UI page protection 

Weeks 19–20: Results Upload Functionality 

CSV import (servantId, subject\_scores, ...) 

Manual entry form alternative 

Preview interface before publishing 

Publish to Firestore with notifications 

Week 20: User Management Dashboard 

Create servant account (auto-username generation) 

Edit servant details (name, department, role) 

Deactivate/reactivate servants 

Password reset functionality 

Audit log of user management actions 

Weeks 20–21: Sync Status Dashboard 

Local cache vs. synced status visibility 

Manual "Sync Now" button 

Conflict resolution UI 

Device online/offline indicator 

Week 21: Reports & Analytics 

Attendance rate per servant (%) 

Week-over-week attendance trends   
Results trends (average scores by term) 

PDF/CSV export functionality 

Weeks 21–22: Google Play Deployment 

App signing setup (keystore generation) 

Release APK build 

Google Play Console account creation 

App description, screenshots, privacy policy 

Internal testing track deployment 

Production release 

Phase 4: Advanced Features & Optimization (Weeks 23–26+)Strategic Goal: Performance optimization, advanced features, production hardening Phase Deliverables: 

✅ Production-ready application 

✅ Advanced features (Face ID, notifications) ready for v1.5 

✅ Performance optimization complete 

✅ Security audit completed 

Development Timeline: 

Week 23–24: Face ID Integration (Optional) 

Requires ML model training (external dependency) 

Architecture reserved for future implementation 

Fallback to manual marking if Face ID unavailable 

Week 24: Notification System 

Firebase Cloud Messaging setup 

New results → servant notifications 

Sync complete → admin notifications 

In-app \+ push notifications 

Week 25: Analytics Dashboard 

Firebase Analytics events 

Daily active users tracking 

Feature usage metrics 

Crash identification and analysis 

Weeks 25–26: Performance Optimization 

Application profiling 

Lazy loading for results/attendance lists 

Pagination for large datasets 

Cache strategy refinement 

Week 26: Security Audit   
Self-administered penetration testing 

Firestore rules audit 

Token security review 

Encryption verification 

Part 6: Real-World Impact & Problem Resolution 

Problem \#1: Student Privacy Violation ✅ SOLVED 

Before: Unauthenticated access—anyone guessing an ID number could view any student's grades 

After: Username \+ Password authentication with Firestore role-based security rules ensures privacy 

Implementation: allow read: if request.auth.uid \== servantId; 

Problem \#2: Single Administrator Dependency ✅ SOLVED 

Before: Service disrupted if single attendance administrator absent 

After: Multiple servants simultaneously mark attendance with role-based permissions Implementation: Distributed mobile app with role-based Firestore access control 

Problem \#3: Offline Reliability ✅ SOLVED 

Before: Unstable church WiFi \= data loss during services 

After: Full offline operation with automatic synchronization when connectivity restored Implementation: Hive local storage \+ Firestore cloud with intelligent conflict resolution 

Problem \#4: Distribution Complexity ✅ SOLVED 

Before: Manual APK distribution to each device, version fragmentation After: Single Google Play submission with automatic updates for all users Implementation: Professional distribution via Google Play Store 

Problem \#5: Data Integrity & Accountability ✅ SOLVED 

Before: No way to verify who accessed what data or when 

After: Complete audit logs with timestamps and user identification 

Implementation: Firestore audit\_logs collection with comprehensive logging 

Problem \#6: Historical Data Limitations ✅ SOLVED

Before: Only current term visible, no historical comparison 

After: Complete term history with visual timeline visualization 

Implementation: Firestore multi-term storage with timeline UI   
Part 7: Implementation Best Practices 

Development Workflow Guidelines 

Offline-First Testing: Always test offline functionality first (disable WiFi) Firebase Emulator: Utilize Firebase emulator for fast, cost-free testing Progressive Rollout: Deploy to beta track before production release Feature Flags: Use Firebase Remote Config for gradual feature enablement Production Monitoring: Daily review of Crashlytics and Analytics 

Security Checklist 

\[ \] Firestore rules prevent public read/write access 

\[ \] JWT tokens expire every 24 hours 

\[ \] Passwords never stored locally (secure storage only) 

\[ \] API keys rotated regularly 

\[ \] Audit logs enabled for sensitive operations 

\[ \] SSL pinning implemented for custom backend 

Quality Assurance Strategy 

| Testing Level  | Tools  | Focus Areas |
| :---- | :---- | ----- |
| Unit Testing  | Unit tests, Mockito  | Auth use cases, sync logic |
| Widget Testing | Widget tests,  WidgetTester | Login forms, attendance lists |
| Integration  Testing | Firebase emulator | End-to-end user  workflows |
| Manual Testing  | Real devices | Offline-to-online  transitions |

Table 4: Quality Assurance Testing Strategy 

Part 8: Risk Assessment & Mitigation Strategies

| Risk Factor  | Potential Impact  | Mitigation Strategy |
| :---- | ----- | :---- |
| Firestore data loss | Complete system failure | Daily automated backups \+ point in-time recovery |
| Token expiry  offline | User login  blockage | Refresh token \+ 24-hour offline grace period |
| Sync conflicts  | Data corruption | Manual resolution UI \+ last-write wins \+ audit |
| Face ID delay  | Phase 2 blockage | Start without Face ID, add v1.5+ later |
| Google Play  rejection | Launch delay | Early submission (Week 20, not 22\) |
| Large dataset lag | Application  slowness | Pagination \+ lazy loading  implemented day 1 |

Table 5: Risk Assessment and Mitigation Matrix 

Part 9: Critical Clarification Questions 

Before development commencement, address these questions with church leadership: 

1\. Timeline Feasibility: Is 5–6 month delivery timeline realistic given team availability? 

2\. Face ID Priority: Should architecture reserve capacity, or defer to v1.5? 3\. Language Support: Arabic only, or dual English/Arabic interface? 

4\. Report Permissions: Which servant roles access attendance reports? 5\. Export Formats: CSV only, or include PDF reports? 

6\. Data Retention: How long retain historical results? (1 year, 5 years, indefinite?) 7\. Backup Strategy: Implement daily automatic Google Drive backups? 8\. Beta Testing: Can real servants participate in Week 18 testing? 

9\. Play Store Approval: Will church leadership approve submission? 10\. Cloud Costs: Are cloud costs acceptable? (Free tier: $0/month) 

Part 10: Implementation Execution Checklist 

Week 1: Project Initiation

\[ \] Present plan to development team and stakeholders 

\[ \] Create Firebase project (console.firebase.google.com) 

\[ \] Initialize GitHub repository for unified application 

\[ \] Extract and backup data from existing applications 

\[ \] Install Flutter development environment and dependencies   
Weeks 2–3: Authentication Foundation 

\[ \] Complete authentication module implementation 

\[ \] Execute login/logout flow testing 

\[ \] Prepare data migration script 

\[ \] Implement sync engine core logic 

\[ \] Verify Hive local storage operation 

Weeks 4–8: Phase 1 Completion Verification 

\[ \] Confirm data migration complete and verified 

\[ \] Validate security layer operational 

\[ \] Enable team testing of authentication locally 

\[ \] Perform security audit of Phase 1 deliverables 

\[ \] Document Phase 1 completion and lessons learned 

Conclusion 

This unified technical architecture comprehensively addresses every identified real-world problem: 

✅ Security: Username/password authentication with Firestore role-based access control ✅ Offline-First: Complete offline operation with automatic synchronization ✅ Multi-Device Sync: All servants simultaneously mark attendance without bottlenecks ✅ Auto-Distribution: Google Play Store manages updates automatically ✅ Scalability: Firebase infrastructure grows automatically with demand ✅ Auditability: Every action logged with timestamps and user identification ✅ Maintainability: Clean architecture with comprehensive test coverage ✅ Future-Proof: Face ID ready, notification system prepared, analytics enabled 

Strategic Recommendation 

Begin Phase 1 this week by establishing secure authentication and offline-first synchronization foundation. Core features will follow naturally once infrastructure is solid. This phased approach minimizes risk while building toward production deployment within the 20–26 week timeline. 

Next Steps 

Immediate Actions: 

Review plan with development team and church leadership 

Answer clarification questions (Part 9\) 

Set up Firebase project 

Initialize Flutter development environment 

Begin Week 1 project initiation tasks 

Next Meeting: Final plan review \+ team questions clarication 

Status: Ready for Implementation  
Prepared by: Kerollos \+ Barthy \+ Technical Analysis

Document prepared for Church Leadership and Development Team Version 1.0 | December 27, 2025 | Ready for Implementation 