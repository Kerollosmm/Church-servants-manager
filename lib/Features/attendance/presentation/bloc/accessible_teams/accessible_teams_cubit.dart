import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccessibleTeamsCubit extends Cubit<AccessibleTeamsState> {
  AccessibleTeamsCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const AccessibleTeamsInitial());

  final TeamRepository _teamRepository;
  StreamSubscription<List<TeamModel>>? _subscription;

  void load(AuthUser actor) {
    emit(const AccessibleTeamsLoading());
    _subscription?.cancel();

    _subscription = _teamRepository.watchAllTeams().listen(
      (teams) {
        final filtered = _filterTeamsForActor(actor, teams);
        emit(AccessibleTeamsLoaded(actor: actor, teams: filtered));
      },
      onError: (_) {
        emit(const AccessibleTeamsError('تعذر تحميل الفرق المتاحة حالياً.'));
      },
    );
  }

  List<TeamModel> _filterTeamsForActor(AuthUser actor, List<TeamModel> teams) {
    final activeTeams = teams
        .where((team) => team.isActive)
        .toList(growable: false);
    if (actor.role == UserRole.admin) {
      return activeTeams;
    }
    if (actor.role == UserRole.servant) {
      final assignedIds = actor.effectiveAssignedTeamIds.toSet();
      return activeTeams
          .where((team) => assignedIds.contains(team.id))
          .toList(growable: false);
    }
    return const <TeamModel>[];
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

sealed class AccessibleTeamsState extends Equatable {
  const AccessibleTeamsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AccessibleTeamsInitial extends AccessibleTeamsState {
  const AccessibleTeamsInitial();
}

final class AccessibleTeamsLoading extends AccessibleTeamsState {
  const AccessibleTeamsLoading();
}

final class AccessibleTeamsLoaded extends AccessibleTeamsState {
  const AccessibleTeamsLoaded({required this.actor, required this.teams});

  final AuthUser actor;
  final List<TeamModel> teams;

  @override
  List<Object?> get props => [actor, teams];
}

final class AccessibleTeamsError extends AccessibleTeamsState {
  const AccessibleTeamsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
