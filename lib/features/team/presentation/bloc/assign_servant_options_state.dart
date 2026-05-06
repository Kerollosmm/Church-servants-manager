import 'package:church_management_system/features/servant/data/models/servant_models.dart';

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
