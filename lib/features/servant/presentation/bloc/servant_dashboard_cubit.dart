import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardState {
  final bool isLoading;
  final List<String> teamNames;
  final String? errorMessage;

  const ServantDashboardState({
    this.isLoading = false,
    this.teamNames = const <String>[],
    this.errorMessage,
  });
}

class ServantDashboardCubit extends Cubit<ServantDashboardState> {
  ServantDashboardCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const ServantDashboardState());

  final TeamRepository _teamRepository;

  Future<void> loadAssignedTeamNames(List<String> assignedTeamIds) async {
    if (assignedTeamIds.isEmpty) {
      emit(const ServantDashboardState());
      return;
    }

    emit(const ServantDashboardState(isLoading: true));

    try {
      final teams = await _teamRepository.getTeamsByIds(assignedTeamIds);
      final names = <String>[];
      for (var id in assignedTeamIds) {
        String? foundName;
        for (final t in teams) {
          if (t.id == id) {
            foundName = t.name.trim();
            break;
          }
        }
        if (foundName != null && foundName.isNotEmpty) {
          names.add(foundName);
        } else {
          names.add('Unknown team');
        }
      }
      emit(ServantDashboardState(teamNames: names));
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'ServantDashboardCubit: failed to load team names '
          '(${error.runtimeType})',
        );
      }
      emit(
        const ServantDashboardState(
          errorMessage: 'Failed to load assigned teams.',
        ),
      );
    }
  }
}
