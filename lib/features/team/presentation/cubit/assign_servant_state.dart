import 'package:church_management_system/features/servant/domain/entities/servant.dart';

abstract class AssignServantState {
  const AssignServantState();
}

class AssignServantInitial extends AssignServantState {
  const AssignServantInitial();
}

class AssignServantLoading extends AssignServantState {
  const AssignServantLoading();
}

class AssignServantLoaded extends AssignServantState {
  final List<Servant> servants;
  const AssignServantLoaded(this.servants);
}

class AssignServantError extends AssignServantState {
  final String message;
  const AssignServantError(this.message);
}
