import 'dart:developer' as developer;
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignServantOptionsState {
  final bool isLoading;
  final List<ServantModel> servants;
  final bool isFromCache;
  final String? errorMessage;

  const AssignServantOptionsState({
    this.isLoading = false,
    this.servants = const <ServantModel>[],
    this.isFromCache = false,
    this.errorMessage,
  });
}

class AssignServantOptionsCubit extends Cubit<AssignServantOptionsState> {
  AssignServantOptionsCubit({required ServantDataRepository servantRepository})
    : _servantRepository = servantRepository,
      super(const AssignServantOptionsState(isLoading: true));

  final ServantDataRepository _servantRepository;

  Future<void> load(String groupId) async {
    emit(const AssignServantOptionsState(isLoading: true));
    try {
      final result = await _servantRepository.getServantsByGroupWithFallback(
        groupId,
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
        name: 'AssignServantOptionsCubit',
      );
      emit(
        const AssignServantOptionsState(
          errorMessage: 'فشل تحميل الخدام. حاول مرة أخرى.',
        ),
      );
    }
  }
}
