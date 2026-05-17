import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/team/presentation/cubit/assign_servant_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignServantCubit extends Cubit<AssignServantState> {
  final IServantRepository _servantRepository;

  AssignServantCubit({required IServantRepository servantRepository})
      : _servantRepository = servantRepository,
        super(const AssignServantInitial());

  Future<void> loadServants(String groupId) async {
    emit(const AssignServantLoading());
    try {
      final result = await _servantRepository.getServantsByGroupWithFallback(groupId);
      final unique = _deduplicate(result.servants);
      emit(AssignServantLoaded(unique));
    } catch (e) {
      emit(AssignServantError(e.toString()));
    }
  }

  List<ServantModel> _deduplicate(List<ServantModel> servants) {
    final seen = <String>{};
    return servants.where((s) => seen.add(s.docID)).toList();
  }

  String? normalizeSelectedId(String? id, List<ServantModel> servants) {
    if (id == null) return null;
    return servants.any((s) => s.docID == id) ? id : null;
  }

  ServantModel? findServant(List<ServantModel> servants, String? id) {
    if (id == null) return null;
    try {
      return servants.firstWhere((s) => s.docID == id);
    } catch (_) {
      return null;
    }
  }
}
