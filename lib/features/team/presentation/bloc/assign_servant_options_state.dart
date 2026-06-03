import 'package:church_management_system/features/servant/domain/entities/servant.dart';

class AssignServantOptionsState {
  final bool isLoading;
  final List<Servant> servants;
  final bool isFromCache;
  final String? errorMessage;

  const AssignServantOptionsState({
    this.isLoading = false,
    this.servants = const <Servant>[],
    this.isFromCache = false,
    this.errorMessage,
  });
}
