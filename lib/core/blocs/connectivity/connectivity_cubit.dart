import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    await _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<bool> _isReachable() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup(
        'firestore.googleapis.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none)) {
      emit(const ConnectivityOffline());
      return;
    }

    final reachable = await _isReachable();
    if (reachable) {
      emit(const ConnectivityOnline());
    } else {
      emit(const ConnectivityOffline());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
