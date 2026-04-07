/// Tracks auth validation freshness to determine whether write operations
/// are permitted. Per spec AC-11.2/AC-11.3, writes are allowed only within
/// 15 minutes of the last successful auth validation.
///
/// The [nowProvider] parameter (DateTime Function()) is injected for
/// testability, allowing tests to control the current time without
/// relying on real clock progression.
class AuthFreshnessPolicy {
  AuthFreshnessPolicy({
    Duration? freshnessWindow,
    DateTime Function()? nowProvider,
  }) : _freshnessWindow = freshnessWindow ?? const Duration(minutes: 15),
       _nowProvider = nowProvider ?? DateTime.now;

  final Duration _freshnessWindow;
  final DateTime Function() _nowProvider;

  DateTime? _lastValidationAt;

  /// Record a successful auth validation. Resets the freshness window.
  void recordValidation() {
    _lastValidationAt = _nowProvider();
  }

  /// Returns true if the last auth validation was within the freshness window.
  /// Returns false if no validation has ever been recorded or the window expired.
  bool get canPerformWrites {
    final last = _lastValidationAt;
    if (last == null) return false;
    return _nowProvider().difference(last) < _freshnessWindow;
  }

  /// Returns the time remaining until the freshness window expires.
  /// Returns zero if no validation has been recorded or the window already expired.
  Duration get timeRemaining {
    final last = _lastValidationAt;
    if (last == null) return Duration.zero;
    final elapsed = _nowProvider().difference(last);
    final remaining = _freshnessWindow - elapsed;
    return remaining > Duration.zero ? remaining : Duration.zero;
  }

  /// Reset the freshness state (e.g., on sign-out).
  void reset() {
    _lastValidationAt = null;
  }
}
