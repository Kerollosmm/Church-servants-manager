# Phase 1 — Tasks: Core Blocs & Cubits

- [X] T1-01 Read & annotate `auth_bloc.dart` (list responsibilities per method)
- [X] T1-02 Create `lib/features/auth/domain/use_cases/sign_in_use_case.dart`
- [X] T1-03 Create `lib/features/auth/domain/use_cases/sign_out_use_case.dart`
- [X] T1-04 Create `lib/features/auth/domain/use_cases/observe_auth_state_use_case.dart`
- [X] T1-05 Register auth use cases in `lib/core/di/injection.dart`
- [X] T1-06 Update `auth_bloc.dart` to delegate to use cases (target: <120 lines)
- [X] T1-07 `flutter analyze` + `flutter test` — auth bloc

- [X] T1-08 Read & annotate `servant_data_cubit.dart`
- [X] T1-09 Create `lib/features/servant/domain/use_cases/get_servants_use_case.dart`
- [X] T1-10 Create `lib/features/servant/domain/use_cases/add_servant_use_case.dart`
- [X] T1-11 Create `lib/features/servant/domain/use_cases/update_servant_use_case.dart`
- [X] T1-12 Create `lib/features/servant/domain/use_cases/delete_servant_use_case.dart`
- [X] T1-13 Create `lib/features/servant/domain/use_cases/filter_servants_use_case.dart`
- [X] T1-14 Register servant use cases in DI
- [X] T1-15 Update `servant_data_cubit.dart` to delegate (target: <150 lines)
- [X] T1-16 `flutter analyze` + `flutter test` — servant cubit

- [X] T1-17 Read & annotate `student_data_bloc.dart`
- [X] T1-18 Create `lib/features/student/domain/use_cases/get_students_use_case.dart`
- [X] T1-19 Create `lib/features/student/domain/use_cases/search_students_use_case.dart`
- [X] T1-20 Create `lib/features/student/domain/use_cases/add_student_use_case.dart`
- [X] T1-21 Create `lib/features/student/domain/use_cases/update_student_use_case.dart`
- [X] T1-22 Create `lib/features/student/domain/use_cases/delete_student_use_case.dart`
- [X] T1-23 Register student use cases in DI
- [X] T1-24 Update `student_data_bloc.dart` to delegate (target: <150 lines)
- [X] T1-25 `flutter analyze` + `flutter test` — student bloc

- [X] T1-26 Read & annotate `team_cubit.dart`
- [X] T1-27 Create `lib/features/team/domain/use_cases/get_teams_use_case.dart`
- [X] T1-28 Create `lib/features/team/domain/use_cases/create_team_use_case.dart`
- [X] T1-29 Create `lib/features/team/domain/use_cases/assign_servant_to_team_use_case.dart`
- [X] T1-30 Register team use cases in DI
- [X] T1-31 Update `team_cubit.dart` to delegate (target: <120 lines)
- [X] T1-32 `flutter analyze` + `flutter test` — team cubit

- [ ] T1-33 Manual end-to-end verification (sign in, servant list, student list, team list)
- [ ] T1-34 Mark phase 1 complete — ready for Phases 2-7
