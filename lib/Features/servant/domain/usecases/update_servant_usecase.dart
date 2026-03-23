import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';

// FIX [P1]: extracted servant update orchestration behind a use case.
class UpdateServantUseCase {
  const UpdateServantUseCase(this._repository);

  final ServantDataRepository _repository;

  Future<void> call(ServantModel servant) {
    return _repository.updateServant(servant);
  }
}
