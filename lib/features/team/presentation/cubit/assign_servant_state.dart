import 'package:church_management_system/features/servant/data/models/servant_models.dart';

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
  final List<ServantModel> servants;
  const AssignServantLoaded(this.servants);
}

class AssignServantError extends AssignServantState {
  final String message;
  const AssignServantError(this.message);
}
