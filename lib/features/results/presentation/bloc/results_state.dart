import 'package:church_management_system/features/results/domain/entities/result.dart';
import 'package:equatable/equatable.dart';

abstract class ResultsState extends Equatable {
  const ResultsState();

  @override
  List<Object?> get props => [];
}

class ResultsInitial extends ResultsState {}

class ResultsLoading extends ResultsState {}

class ResultsLoaded extends ResultsState {
  final List<Result> results;
  final bool isFromCache;

  const ResultsLoaded({required this.results, this.isFromCache = false});

  @override
  List<Object?> get props => [results, isFromCache];
}

class ResultsError extends ResultsState {
  final String message;

  const ResultsError({required this.message});

  @override
  List<Object?> get props => [message];
}
