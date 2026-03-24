**Church Management System**

Principal Engineer Code Review

Reviewed: March 2026    Branch: feature/attendance (lib.zip)

# **Overall Verdict**

| Architecture | State Management | Code Quality | UX Readiness |
| :---: | :---: | :---: | :---: |
| **Strong** | **Strong** | **Needs polish** | **Needs polish** |

This is a well-architected Flutter \+ Firebase application demonstrating clear Clean Architecture discipline, proper BLoC/Cubit state management, and robust Firestore integration patterns. The attendance module in particular is notably sophisticated. Several correctness issues and DX rough edges exist that should be addressed before adding new features.

# **1\. Architecture & DI**

## **1.1 Strengths**

* ✅  Proper 3-layer Clean Architecture (data / domain / presentation) consistently applied across all features.

* ✅  GetIt DI container is well-structured with clear sections: External / Services / Repositories / UseCases / Routing.

* ✅  Correct use of registerLazySingleton for stateful services and registerFactory for use cases.

* ✅  IAttendanceRepository and IStudentRepository abstractions allow testable boundaries.

* ✅  AppRouter is a plain Dart class, not a widget, which keeps routing logic testable.

## **1.2 Issues**

| File | Issue | Severity | Fix |
| :---- | :---- | ----- | :---- |
| injection.dart | StudentLinkedUserSyncService is registered AFTER StudentDataRepository which depends on it. GetIt will resolve lazily, but registration order can mask wiring errors. | **Medium** | Register all dependencies before their dependents. Move StudentLinkedUserSyncService above StudentDataRepository. |
| app\_router.dart | \_withStudentDataBloc mixes context.read\<\> and getIt\<\> for the same BLoC's use cases. Some use cases are read from context (which requires them to be provided upstream) while others use getIt. | **High** | Pick one strategy: use getIt consistently inside AppRouter since it is not a widget and has no BuildContext in its class body. |
| app\_router.dart | StudentDataBloc is instantiated in the router, not in DI. This couples routing to BLoC instantiation details. | **Medium** | Consider registerFactory\<StudentDataBloc\> in injection.dart and call getIt\<StudentDataBloc\> from the route builder. |
| injection.dart | StudentDataRepository is registered twice: once as StudentDataRepository and once via IStudentRepository alias. The alias pattern is correct but a comment explaining it is missing. | **Low** | Add a comment // IStudentRepository \-\> StudentDataRepository (alias). |

# **2\. State Management**

## **2.1 Strengths**

* ✅  Sealed state classes with exhaustive switch — excellent pattern for safe UI branching.

* ✅  AttendanceTakingCubit correctly separates stream subscriptions (roster watch) from mutation state (\_isMutating / \_mutationError as instance fields).

* ✅  copyWith with clearMutationError boolean flag is a clean pattern for one-shot error clearing.

* ✅  \_runMutation guards against concurrent mutations with \_isMutating flag.

* ✅  StudentDataBloc correctly uses Completer for tracking refresh completion with timeout.

## **2.2 Issues**

| File | Issue | Severity | Fix |
| :---- | :---- | ----- | :---- |
| attendance\_taking\_cubit.dart | After await action() in \_runMutation, the code reads \`final latestState \= state\`. A Firestore stream emission may have changed state between the mutation and this read, causing the mutation error to be lost. | **High** | Capture state before the mutation starts, then apply delta fields explicitly rather than re-reading state after the await. |
| team\_members\_cubit.dart | TeamMembersState does not extend Equatable and has no custom \== / hashCode. Every emit() will trigger rebuilds even if nothing changed. | **Medium** | Add Equatable extends or implement \== / hashCode. Consider using freezed for this class. |
| student\_data\_state.dart | StudentDataLoaded implements custom \== / hashCode by hand. This is brittle (fields added later will be silently omitted). | **Medium** | Use Freezed @freezed \+ @With for auto-generated equality. |
| role\_router.dart | RoleRouter.resolve() casts state as AuthDegraded after the ternary, which will throw if state is unexpectedly a different type. | **High** | Use a pattern match: if (state case AuthDegraded(:final message)) { ... } else { ... } |
| student\_data\_bloc.dart | // FIX \[P1\] comment in constructor acknowledges optional use cases with in-place fallback constructors. This leaks concrete classes through the BLoC constructor. | **Medium** | Make all use case params required and remove fallback constructors. Enforce injection from DI container only. |

# **3\. Code Quality**

## **3.1 Strengths**

* ✅  Handler functions extracted as top-level functions (part of) in student\_data\_bloc\_handlers.dart — keeps the BLoC class lean.

* ✅  kDebugMode guards on all debugPrint calls — no logging in release builds.

* ✅  Firestore offline persistence configured with a bounded 100MB cache.

* ✅  Deterministic session IDs (dateKey \+ timestamp \+ slug) prevent duplicate writes.

* ✅  \_buildArgsValidatedRoute\<T\> generic helper eliminates boilerplate across all routes.

* ✅  main.dart wraps runApp in runZonedGuarded with both FlutterError.onError and PlatformDispatcher.onError.

## **3.2 Issues**

| File | Issue | Severity | Fix |
| :---- | :---- | ----- | :---- |
| validators.dart | Validators has parallel English and Arabic versions of every method (validateEmail / validateEmailArabic etc.). The logic is identical — only the string literals differ. | **Medium** | Extract a private \_validate(value, emptyMsg, invalidMsg) helper and call it from both public methods. Or deprecate the English variants if they are unused. |
| validators.dart | English validators (validateEmail, validatePassword, validateName) appear unused in the UI which is fully Arabic. Dead code. | **Low** | Delete or mark @deprecated with a removal date. |
| app\_colors.dart | Many 'legacy alias' fields (surfaceContainer \= surfaceContainerLow, textPrimary \= onBackground, etc.) create ambiguity about which token to use. | **Low** | Mark legacy aliases @Deprecated('Use onBackground instead'). Migrate call sites and remove in next refactor. |
| student\_management\_coordinator.dart | TeamCubit is instantiated manually in initState using a mix of context.read and getIt. | **Medium** | Register TeamCubit in DI as registerFactory and provide it via BlocProvider in the route builder. |
| app\_router.dart line \~44 | \_buildMessageRoute shows a raw Text(message) for invalid args — no back button, styling, or indication to users what went wrong. | **Low** | Replace with NotFoundScreen or a dedicated ErrorScreen widget. |

# **4\. UX & Accessibility**

## **4.1 Observations**

* ✅  AttendanceTakingCubit exposes isMutating on state, which is the correct pattern for disabling buttons during operations.

* ✅  AuthDegraded state with AdminRefreshRequiredScreen is a thoughtful degraded-mode UX.

* ✅  studentDataLoading.hasPreviousStudents enables skeleton-vs-full-loader differentiation in the UI.

## **4.2 Missing or Weak UX**

* 🔶  No pagination or lazy loading for student/servant lists. All data is loaded into memory. With large churches (500+ students), this will cause noticeable latency and memory pressure.

* 💡  No network connectivity indicator. Firestore offline cache silently serves stale data without informing the user.

* 💡  mutationError in attendance\_taking is shown only if the UI reads it from state — verify the screen actually consumes and displays this field.

* 💡  No haptic feedback on attendance mark/unmark actions (present / late buttons). Standard for fast-tap workflows.

* 💡  No empty-state image in the attendance roster when there are no students in a team.

* 💡  Session expiry checked only at mutation time (\_runMutation). There is no proactive warning shown to users as the session approaches its end time.

# **5\. Feature Suggestions**

## **5.1 Short-term (next sprint)**

* 💡  Optimistic UI for attendance marking: update the roster item locally before the Firestore write resolves, then revert on error. Eliminates perceived lag.

* 💡  Swipe-to-mark gesture on roster items (swipe right \= present, left \= late) for faster data entry.

* 💡  Bulk mark confirmation dialog: before markAllRemainingPresent fires, show a count ('Mark 12 students as present?').

* 💡  Session countdown timer banner: show remaining time when \< 10 minutes left on a session.

## **5.2 Medium-term**

* 💡  Attendance export: generate a CSV or PDF summary per session or per student, downloadable by admin.

* 💡  Push notifications (FCM): notify servants when a new session is created for their team.

* 💡  Biometric/PIN lock for sensitive admin screens (servant list, student personal data).

* 💡  Offline-first indicator widget: persistent banner when the device is offline, informing that shown data may be cached.

# **6\. Prioritized Fix List**

Address in this order before the next feature sprint:

**P1 — Fix This Week**

* ⛔  \[P1-A\]  app\_router.dart — Replace context.read mix with consistent getIt in \_withStudentDataBloc.

* ⛔  \[P1-B\]  role\_router.dart — Replace unsafe (state as AuthDegraded) cast with pattern match.

* ⛔  \[P1-C\]  attendance\_taking\_cubit.dart — Capture state snapshot before await to avoid race in \_runMutation.

**P2 — Fix This Month**

* 🔶  \[P2-A\]  team\_members\_cubit.dart — Add Equatable or \== / hashCode to TeamMembersState.

* 🔶  \[P2-B\]  injection.dart — Reorder registrations so dependencies precede dependents.

* 🔶  \[P2-C\]  validators.dart — Consolidate duplicate English/Arabic validators.

* 🔶  \[P2-D\]  student\_data\_bloc.dart — Make all use case constructor params required.

* 🔶  \[P2-E\]  student\_management\_coordinator.dart — Register TeamCubit in DI container.

**P3 — Backlog**

* 💡  \[P3-A\]  app\_colors.dart — @Deprecate legacy color aliases.

* 💡  \[P3-B\]  Implement Firestore pagination for student/servant lists.

* 💡  \[P3-C\]  Add network offline indicator widget.

* 💡  \[P3-D\]  Add session expiry countdown banner in attendance taking screen.