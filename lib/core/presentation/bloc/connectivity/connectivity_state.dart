import 'package:equatable/equatable.dart';

// FIX [008]: Connectivity state for the global ConnectivityCubit. (T004)

/// Represents the app-wide network connectivity status.
final class ConnectivityState extends Equatable {
  const ConnectivityState({required this.isOffline});

  /// True when the device has no active network interface.
  final bool isOffline;

  /// Convenience: true when online.
  bool get isOnline => !isOffline;

  @override
  List<Object?> get props => [isOffline];
}
