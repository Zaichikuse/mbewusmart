/// In-memory cache for diagnosis category lookups.
/// Caches results for 60 seconds to avoid repeated Firestore queries.
/// Thread-safe and auto-expires entries.
class DiagnosisCategoryCache {
  static final DiagnosisCategoryCache _instance =
      DiagnosisCategoryCache._internal();

  final Map<String, _CacheEntry<String>> _cache = {};
  static const Duration _cacheTTL = Duration(seconds: 60);

  DiagnosisCategoryCache._internal();

  factory DiagnosisCategoryCache() {
    return _instance;
  }

  /// Get category from cache if available and not expired.
  String? get(String diagnosisName) {
    final entry = _cache[diagnosisName];
    if (entry != null && !entry.isExpired) {
      return entry.value;
    }
    // Remove expired entry
    if (entry != null && entry.isExpired) {
      _cache.remove(diagnosisName);
    }
    return null;
  }

  /// Store category in cache with TTL.
  void set(String diagnosisName, String category) {
    _cache[diagnosisName] = _CacheEntry(
      value: category,
      expiresAt: DateTime.now().add(_cacheTTL),
    );
  }

  /// Clear all cache entries.
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries (useful for periodic cleanup).
  void clearExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Get cache size (for debugging).
  int get size => _cache.length;
}

/// Internal cache entry with expiration time.
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
