import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

/// Encrypts/decrypts PII (names, phones) before sending to Firestore.
///
/// Uses a SHARED AES-256 key derived from a deployment passphrase.
/// All authorized installs use the same key so managers can decrypt
/// farmer data; attackers without the app cannot decrypt it.
class PiiEncryptionService {
  // Deployment passphrase — in production this would come from MDM,
  // not hardcoded. For this school project it's embedded.
  static const String _deploymentPassphrase =
      'mbewusmart-malawi-extension-officer-shared-v1-2026';
  static const String _deploymentSalt = 'mbewusmart-pii-salt-do-not-change';
  static const String _piiKeyStorageKey = 'mbewusmart_pii_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static enc.Key? _cachedKey;
  static enc.Encrypter? _cachedEncrypter;

  static Future<enc.Key> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final stored = await _secureStorage.read(key: _piiKeyStorageKey);
    if (stored != null) {
      _cachedKey = enc.Key(Uint8List.fromList(base64Decode(stored)));
      return _cachedKey!;
    }

    // Derive 256-bit AES key from passphrase via SHA-256
    final combined = '$_deploymentPassphrase:$_deploymentSalt';
    final digest = sha256.convert(utf8.encode(combined));
    final keyBytes = Uint8List.fromList(digest.bytes);

    await _secureStorage.write(
      key: _piiKeyStorageKey,
      value: base64Encode(keyBytes),
    );
    _cachedKey = enc.Key(keyBytes);
    return _cachedKey!;
  }

  static Future<enc.Encrypter> _getEncrypter() async {
    if (_cachedEncrypter != null) return _cachedEncrypter!;
    final key = await _getKey();
    _cachedEncrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return _cachedEncrypter!;
  }

  /// Encrypts a string. Returns "iv_base64:ciphertext_base64".
  static Future<String?> encryptString(String? plaintext) async {
    if (plaintext == null || plaintext.isEmpty) return null;
    final encrypter = await _getEncrypter();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a string. Returns the plaintext or null on failure.
  /// If the input doesn't look encrypted (no ':'), returns it as-is
  /// (handles legacy/migration cases).
  static Future<String?> decryptString(String? ciphertext) async {
    if (ciphertext == null || ciphertext.isEmpty) return null;
    if (!ciphertext.contains(':')) return ciphertext;

    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return ciphertext;
      final encrypter = await _getEncrypter();
      final iv = enc.IV.fromBase64(parts[0]);
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return ciphertext;
    }
  }

  /// Synchronous decryption for use in widgets. Returns null if the
  /// key isn't warmed up yet — caller should show a placeholder.
  static String? decryptStringSync(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return null;
    if (!ciphertext.contains(':')) return ciphertext;
    if (_cachedEncrypter == null) return null;
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return ciphertext;
      final iv = enc.IV.fromBase64(parts[0]);
      return _cachedEncrypter!.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return null;
    }
  }

  /// Pre-loads the encryption key during app startup so [decryptStringSync]
  /// works in widgets.
  static Future<void> warmUp() async {
    await _getEncrypter();
  }
}
