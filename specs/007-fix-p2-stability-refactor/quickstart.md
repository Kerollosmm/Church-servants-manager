# Quickstart: P2 Stability and Correctness Refactor

## Setup
1. Ensure you are on the branch `007-fix-p2-stability-refactor`.
2. Run `flutter pub get` to ensure all dependencies are resolved.

## Implementation Steps
1. **TeamMembersState**: 
   - Modify `lib/features/team/presentation/cubit/team_members_state.dart`.
   - Implement `Equatable` or override `==` and `hashCode`.
2. **Dependency Injection**:
   - Reorder registrations in `lib/core/di/injection.dart`.
   - Ensure `StudentLinkedUserSyncService` is registered before `StudentDataRepository`.
   - Register `TeamCubit` as a factory.
3. **Validators**:
   - Refactor `lib/core/utils/validators.dart` to use a shared internal validation logic.
4. **StudentDataBloc**:
   - Update `lib/features/students/presentation/bloc/student_data_bloc.dart`.
   - Make use case parameters required and remove fallback logic.

## Verification
1. Run `flutter test` to ensure no regressions.
2. Use DevTools to verify that `TeamMembersState` emissions with identical data do not trigger UI rebuilds.
3. Verify app startup logs for correct dependency resolution order.
