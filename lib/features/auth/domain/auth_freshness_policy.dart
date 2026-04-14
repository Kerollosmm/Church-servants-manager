import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage key for persisting validation timestamp
const _kLastValidationKey = 'auth_freshness_last_validation_at';

/// Tracks auth validation freshness to determine whether write operations
/// are permitted. Per spec AC-11.2/AC-11.3, writes are allowed only within
/// 15 minutes of the last successful auth validation.
///
/// PERSISTENCE:
/// - Validation timestamp is persisted to FlutterSecureStorage
/// - On cold start, timestamp is restored from secure storage
/// - Cross-validates with Firebase token issuedAt time (uses most recent)
///
/// The [nowProvider] parameter (DateTime Function()) is injected for
/// testability, allowing tests to control the current time without
/// relying on real clock progression.
class AuthFreshnessPolicy {
  AuthFreshnessPolicy({
    Duration? freshnessWindow,
    DateTime Function()? nowProvider,
    FlutterSecureStorage? secureStorage,
    this.tokenIssuedAtProvider,
  }) : _freshnessWindow = freshnessWindow ?? const Duration(minutes: 15),
       _nowProvider = nowProvider ?? DateTime.now,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           );

  final Duration _freshnessWindow;
  final DateTime Function() _nowProvider;
  final FlutterSecureStorage _secureStorage;
  final Future<DateTime?> Function()? tokenIssuedAtProvider;

  DateTime? _lastValidationAt;
  bool _initialized = false;

  /// Initialize the policy by loading persisted state.
  /// Must be called once at app startup before checking canPerformWrites.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load timestamp from secure storage
      final storedAtStr = await _secureStorage.read(key: _kLastValidationKey);
      if (storedAtStr != null) {
        final storedAt = DateTime.parse(storedAtStr);
        _lastValidationAt = storedAt;
      }

      // Cross-validate with Firebase token
      final tokenIssuedAt = await _getTokenIssuedAt();
      if (tokenIssuedAt != null) {
        // Use the MORE RECENT of the two timestamps
        if (_lastValidationAt == null ||
            tokenIssuedAt.isAfter(_lastValidationAt!)) {
          _lastValidationAt = tokenIssuedAt;
        }
      }

      _initialized = true;
    } catch (e, s) {
      // If initialization fails, start with null state (deny writes)
      developer.log('Secure storage read error', error: e, stackTrace: s);
      _lastValidationAt = null;
      _initialized = true;
    }
  }

  /// Record a successful auth validation. Resets the freshness window.
  /// Persists timestamp to secure storage for cold-start recovery.
  Future<void> recordValidation() async {
    final now = _nowProvider();
    _lastValidationAt = now;

    try {
      await _secureStorage.write(
        key: _kLastValidationKey,
        value: now.toIso8601String(),
      );
    } catch (e, s) {
      // If storage fails, keep in-memory state (graceful degradation)
      developer.log('Secure storage write error', error: e, stackTrace: s);
    }
  }

  /// Returns true if the last auth validation was within the freshness window.
  /// Returns false if no validation has ever been recorded or the window expired.
  ///
  /// PERSISTENCE: Works correctly after cold start — timestamp is restored
  /// from secure storage on [initialize()].
  bool get canPerformWrites {
    if (!_initialized) return false; // Must call initialize() first
    final last = _lastValidationAt;
    if (last == null) return false;
    return _nowProvider().difference(last) < _freshnessWindow;
  }

  /// Returns the time remaining until the freshness window expires.
  /// Returns zero if no validation has been recorded or the window already expired.
  Duration get timeRemaining {
    if (!_initialized) return Duration.zero;
    final last = _lastValidationAt;
    if (last == null) return Duration.zero;
    final elapsed = _nowProvider().difference(last);
    final remaining = _freshnessWindow - elapsed;
    return remaining > Duration.zero ? remaining : Duration.zero;
  }

  /// Reset the freshness state (e.g., on sign-out).
  /// Also clears persisted timestamp from secure storage.
  Future<void> reset() async {
    _lastValidationAt = null;
    _initialized = true;

    try {
      await _secureStorage.delete(key: _kLastValidationKey);
    } catch (e, s) {
      // If deletion fails, continue anyway (state is cleared in memory)
      developer.log('Secure storage delete error', error: e, stackTrace: s);
    }
  }

  /// Get the Firebase Auth token issuedAt time.
  /// Returns null if unable to retrieve.
  Future<DateTime?> _getTokenIssuedAt() async {
    try {
      if (tokenIssuedAtProvider != null) {
        return await tokenIssuedAtProvider!();
      }
      return null;
    } catch (e, s) {
      developer.log('Token retrieval error', error: e, stackTrace: s);
      return null;
    }
  }
}
