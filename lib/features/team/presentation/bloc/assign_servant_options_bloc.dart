import 'dart:developer' as developer;

import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/assign_servant_options_event.dart';
import 'package:church_management_system/features/team/presentation/bloc/assign_servant_options_state.dart'; // import state
import 'package:flutter_bloc/flutter_bloc.dart';

export 'assign_servant_options_state.dart' show AssignServantOptionsState;

class AssignServantOptionsBloc
    extends Bloc<AssignServantOptionsEvent, AssignServantOptionsState> {
  final ServantDataRepository _servantRepository;

  AssignServantOptionsBloc({required ServantDataRepository servantRepository})
    : _servantRepository = servantRepository,
      super(const AssignServantOptionsState(isLoading: true)) {
    on<LoadAssignServantOptionsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadAssignServantOptionsEvent event,
    Emitter<AssignServantOptionsState> emit,
  ) async {
    emit(const AssignServantOptionsState(isLoading: true));
    try {
      final result = await _servantRepository.getServantsByGroupWithFallback(
        event.groupId,
      );
      emit(
        AssignServantOptionsState(
          servants: result.servants,
          isFromCache: result.isFromCache,
        ),
      );
    } catch (error) {
      developer.log(
        'failed to load servants',
        error: error,
        name: 'AssignServantOptionsBloc',
      );
      emit(
        const AssignServantOptionsState(
          errorMessage: 'فشل تحميل الخدام. حاول مرة أخرى.',
        ),
      );
    }
  }
}
