import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Manages the AES-256 encryption key for Hive boxes.
///
/// The key is generated once on first run and stored in Android Keystore
/// (via flutter_secure_storage). It never leaves secure hardware-backed storage.
class HiveEncryptionService {
  static const String _hiveKeyStorageKey = 'mbewusmart_hive_master_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static List<int>? _cachedKeyBytes;

  /// Gets the Hive encryption cipher. Creates the master key on first call.
  /// All subsequent calls return the same cipher instance (cached).
  static Future<HiveAesCipher> getCipher() async {
    final bytes = await _getKeyBytes();
    return HiveAesCipher(bytes);
  }

  static Future<List<int>> _getKeyBytes() async {
    if (_cachedKeyBytes != null) return _cachedKeyBytes!;

    final stored = await _secureStorage.read(key: _hiveKeyStorageKey);

    if (stored == null) {
      // First run — generate a fresh 256-bit (32 byte) key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      await _secureStorage.write(
        key: _hiveKeyStorageKey,
        value: base64Encode(keyBytes),
      );
      _cachedKeyBytes = keyBytes;
      return keyBytes;
    }

    _cachedKeyBytes = base64Decode(stored);
    return _cachedKeyBytes!;
  }

  /// Used only for development/testing — wipe the key.
  /// WARNING: this makes all existing encrypted data unrecoverable.
  static Future<void> resetKey() async {
    await _secureStorage.delete(key: _hiveKeyStorageKey);
    _cachedKeyBytes = null;
  }
}
