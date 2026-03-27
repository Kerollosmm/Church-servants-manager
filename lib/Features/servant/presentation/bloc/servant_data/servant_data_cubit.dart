import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/usecases/add_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/delete_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/filter_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/get_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/restore_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/update_servant_usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'servant_data_state.dart';

export 'servant_data_state.dart';

part 'servant_data_cubit_actions.dart';

class ServantDataCubit extends Cubit<ServantDataState> {
  // FIX [P1]: delegate servant CRUD and filtering to dedicated use cases.
  ServantDataCubit({
    required ServantDataRepository repository,
    required AdminUserProvisioningService adminUserProvisioningService,
    GetServantsUseCase? getServantsUseCase,
    AddServantUseCase? addServantUseCase,
    UpdateServantUseCase? updateServantUseCase,
    DeleteServantUseCase? deleteServantUseCase,
    FilterServantsUseCase? filterServantsUseCase,
    RestoreServantUseCase? restoreServantUseCase,
  }) : _getServantsUseCase =
           getServantsUseCase ?? GetServantsUseCase(repository),
       _addServantUseCase =
           addServantUseCase ??
           AddServantUseCase(repository, adminUserProvisioningService),
       _updateServantUseCase =
           updateServantUseCase ?? UpdateServantUseCase(repository),
       _deleteServantUseCase =
           deleteServantUseCase ??
           DeleteServantUseCase(repository, adminUserProvisioningService),
       _filterServantsUseCase =
           filterServantsUseCase ?? const FilterServantsUseCase(),
       _restoreServantUseCase =
           restoreServantUseCase ??
           RestoreServantUseCase(repository, adminUserProvisioningService),
       super(const ServantDataInitial());

  final GetServantsUseCase _getServantsUseCase;
  final AddServantUseCase _addServantUseCase;
  final UpdateServantUseCase _updateServantUseCase;
  final DeleteServantUseCase _deleteServantUseCase;
  final FilterServantsUseCase _filterServantsUseCase;
  final RestoreServantUseCase _restoreServantUseCase;

  String? _lastQuery;
  int _lastLimit = 50;
  bool _includeArchived = false;
  List<ServantModel> _allServants = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  ServantDataLoaded? get _loadedState =>
      state is ServantDataLoaded ? state as ServantDataLoaded : null;
}
