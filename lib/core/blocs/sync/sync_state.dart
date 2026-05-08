import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class Syncing extends SyncState {
  final int pendingCount;
  final int totalCount;

  const Syncing({required this.pendingCount, required this.totalCount});

  @override
  List<Object?> get props => [pendingCount, totalCount];
}

class SyncSuccess extends SyncState {
  const SyncSuccess();
}

class SyncFailure extends SyncState {
  final String errorMessage;

  const SyncFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
