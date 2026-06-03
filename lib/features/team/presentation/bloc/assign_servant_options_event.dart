import 'package:equatable/equatable.dart';

abstract class AssignServantOptionsEvent extends Equatable {
  const AssignServantOptionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssignServantOptionsEvent extends AssignServantOptionsEvent {
  final String groupId;

  const LoadAssignServantOptionsEvent(this.groupId);

  @override
  List<Object?> get props => [groupId];
}
