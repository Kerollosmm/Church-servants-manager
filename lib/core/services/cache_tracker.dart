class CacheTracker {
  static final Map<String, DateTime> _lastFetchTimes = {};

  /// Checks if a revalidation fetch is allowed (has been > 15 minutes since the last fetch).
  static bool shouldRevalidate(
    String key, {
    Duration maxAge = const Duration(minutes: 15),
  }) {
    final lastFetch = _lastFetchTimes[key];
    if (lastFetch == null) {
      return true;
    }
    return DateTime.now().difference(lastFetch) > maxAge;
  }

  /// Marks a query key as fetched just now.
  static void markFetched(String key) {
    _lastFetchTimes[key] = DateTime.now();
  }

  /// Manually clears a query key.
  static void clear(String key) {
    _lastFetchTimes.remove(key);
  }
}
