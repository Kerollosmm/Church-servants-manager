import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(const ConnectivityInitial()) {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      emit(const ConnectivityOffline());
    } else {
      emit(const ConnectivityOnline());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
