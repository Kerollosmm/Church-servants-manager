import 'dart:async';

import 'package:church_management_system/core/presentation/bloc/connectivity/connectivity_state.dart';
import 'package:church_management_system/core/services/connectivity_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// FIX [008]: Global cubit that bridges ConnectivityService to the UI layer. (T005)

/// Cubit that exposes network connectivity changes to the widget tree.
///
/// Registered as a lazy singleton in injection.dart and provided globally
/// via MultiBlocProvider in ChurchApp so every screen can react to offline
/// state without duplicating stream subscriptions.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({required ConnectivityService connectivityService})
    : _connectivityService = connectivityService,
      super(const ConnectivityState(isOffline: false)) {
    _subscription = _connectivityService.isOfflineStream.listen(
      (isOffline) => emit(ConnectivityState(isOffline: isOffline)),
      onError: (_) => emit(const ConnectivityState(isOffline: false)),
    );
  }

  final ConnectivityService _connectivityService;
  late final StreamSubscription<bool> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
