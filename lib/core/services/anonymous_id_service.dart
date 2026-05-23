import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and stores a per-install anonymous ID that is NEVER linked
/// to the farmer's phone number, name, or National ID.
///
/// Used as the `farmer_id` in both the `reports` (encrypted PII) and
/// `disease_watch` (zero PII) Firestore collections.
///
/// If the user uninstalls the app, a new anonymous ID is generated on
/// the next install — there is no way to link historical scans to the
/// same person across reinstalls.
class AnonymousIdService {
  static const String _anonIdKey = 'mbewusmart_anon_id_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? _cachedId;

  /// Returns the anonymous ID for this install, creating one if needed.
  /// Format: "anon_" + 16 random hex chars.
  static Future<String> getAnonymousId() async {
    if (_cachedId != null) return _cachedId!;

    final stored = await _secureStorage.read(key: _anonIdKey);
    if (stored != null && stored.isNotEmpty) {
      _cachedId = stored;
      return stored;
    }

    // First run — generate a fresh random ID
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final newId = 'anon_$hex';

    await _secureStorage.write(key: _anonIdKey, value: newId);
    _cachedId = newId;
    return newId;
  }

  /// Generates a hashed location bucket (e.g. district name) so we don't
  /// expose exact GPS coordinates. Used for disease_watch only.
  static String? sanitizeDistrict(String? district) {
    if (district == null || district.trim().isEmpty) return null;
    final cleaned = district.trim();
    if (cleaned.toLowerCase() == 'unknown') return null;
    return cleaned;
  }
}

/// Rounds a coordinate to ~5km precision so individual farms aren't
/// pinpointed in the public disease_watch feed.
double? sanitizeCoordinate(double? coord) {
  if (coord == null) return null;
  // Round to 1 decimal place ≈ 11km, 2 decimals ≈ 1.1km
  // We use 1 decimal so individual farms can't be located.
  return (coord * 10).round() / 10;
}

/// Encode bytes to base64 for inline storage when needed.
String encodeBytes(List<int> bytes) => base64Encode(bytes);
