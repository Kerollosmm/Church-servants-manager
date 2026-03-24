import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

// FIX [008]: New service wrapping connectivity_plus to expose a broadcast
// stream of offline status. Registered as a lazy singleton in injection.dart. (T002)

/// Service that exposes network connectivity status as a broadcast stream.
///
/// Emits `true` when the device has no network connectivity (all results are
/// [ConnectivityResult.none]) and `false` when at least one interface is up.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;
  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Broadcast stream that emits `true` when offline, `false` when online.
  Stream<bool> get isOfflineStream {
    _controller ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _controller?.add(_isOffline(results)),
      onError: (_) => _controller?.add(false),
    );
    // Immediately check and emit the current status.
    _connectivity.checkConnectivity().then(
      (results) => _controller?.add(_isOffline(results)),
      onError: (_) => _controller?.add(false),
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static bool _isOffline(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  /// Dispose resources. Call when the owning scope is destroyed.
  void dispose() {
    _stopListening();
    _controller?.close();
    _controller = null;
  }
}
