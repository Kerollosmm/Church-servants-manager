import 'dart:async';
import 'package:church_management_system/features/results/domain/entities/result.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/results/presentation/bloc/results_event.dart';
import 'package:church_management_system/features/results/presentation/bloc/results_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResultsBloc extends Bloc<ResultsEvent, ResultsState> {
  final IResultsRepository _resultsRepository;

  ResultsBloc({required IResultsRepository resultsRepository})
    : _resultsRepository = resultsRepository,
      super(ResultsInitial()) {
    on<ResultsLoadRequested>(_onLoadRequested);
    on<ResultUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onLoadRequested(
    ResultsLoadRequested event,
    Emitter<ResultsState> emit,
  ) async {
    emit(ResultsLoading());
    try {
      // Configure ResultsBloc to first emit Loaded using Source.cache before attempting a background refresh.
      // The repository already handles cache-first logic in getResultsForServant.
      final response = await _resultsRepository.getResultsForServant(
        event.groupId,
      );
      emit(
        ResultsLoaded(
          results: response.results,
          isFromCache: response.isFromCache,
        ),
      );

      // If we wanted a double-emit (cache then server), we'd need more granular repo methods.
      // For now, the repo's getResultsForServant does cache-then-server internally if cache is empty.
    } catch (e) {
      emit(ResultsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    ResultUpdateRequested event,
    Emitter<ResultsState> emit,
  ) async {
    if (state is ResultsLoaded) {
      final currentState = state as ResultsLoaded;
      final updatedResults = List<Result>.from(currentState.results);
      final index = updatedResults.indexWhere(
        (r) => r.studentId == event.result.studentId,
      );

      if (index != -1) {
        updatedResults[index] = event.result;
      } else {
        updatedResults.add(event.result);
      }

      // Optimistic update
      emit(
        ResultsLoaded(
          results: updatedResults,
          isFromCache: currentState.isFromCache,
        ),
      );
    }

    try {
      await _resultsRepository.updateResult(event.result);
    } catch (e) {
      // Revert or show error
      emit(ResultsError(message: e.toString()));
    }
  }
}
