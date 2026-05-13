import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:equatable/equatable.dart';

abstract class ResultsEvent extends Equatable {
  const ResultsEvent();

  @override
  List<Object?> get props => [];
}

class ResultsLoadRequested extends ResultsEvent {
  final String groupId;

  const ResultsLoadRequested({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class ResultUpdateRequested extends ResultsEvent {
  final ResultsModel result;

  const ResultUpdateRequested({required this.result});

  @override
  List<Object?> get props => [result];
}
