import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<User> login(String phoneNumber, String? pin);
  Future<User> register({
    required String fullName,
    required String phoneNumber,
    String? nationalId,
    required UserRole role,
    String? pin,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isUserRegistered(String phoneNumber);
  Future<void> saveUser(User user);

  /// Verify a PIN against the stored hash for a user with this phone number.
  Future<bool> verifyPin({required String phoneNumber, required String pin});

  /// Change the PIN for a user. Returns the updated user.
  Future<User> changePin({required String userId, required String newPin});

  /// Decrypt and return the user's National ID for display purposes.
  /// Returns null if no NID is stored.
  Future<String?> getDecryptedNationalId(String userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box userBox;
  final FlutterSecureStorage _secureStorage;

  // Secure storage keys for the AES master key
  static const String _aesKeyStorageKey = 'mbewusmart_aes_master_key_v1';

  // bcrypt cost factor — higher = slower = more secure
  // 12 takes ~250ms per hash. Default Spring Boot uses 10.
  static const int _bcryptCost = 12;

  // Cached AES key after first load (avoid hitting secure storage repeatedly)
  enc.Key? _cachedAesKey;

  AuthLocalDataSourceImpl(this.userBox, {FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  // ============================================================
  // ENCRYPTION KEY MANAGEMENT
  // ============================================================

  /// Gets the AES-256 master key, creating it on first run.
  /// The key is stored in Android Keystore (hardware-backed where available).
  Future<enc.Key> _getAesKey() async {
    if (_cachedAesKey != null) return _cachedAesKey!;

    String? base64Key = await _secureStorage.read(key: _aesKeyStorageKey);

    if (base64Key == null) {
      // First run — generate a new 256-bit random key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      base64Key = base64Encode(keyBytes);
      await _secureStorage.write(key: _aesKeyStorageKey, value: base64Key);
    }

    _cachedAesKey = enc.Key(base64Decode(base64Key));
    return _cachedAesKey!;
  }

  // ============================================================
  // PIN HASHING (bcrypt)
  // ============================================================

  /// Hash a PIN using bcrypt. Returns a string that contains both the salt
  /// and the hash, so we don't need to store the salt separately.
  String _hashPinSync(String pin) {
    final salt = BCrypt.gensalt(logRounds: _bcryptCost);
    return BCrypt.hashpw(pin, salt);
  }

  /// Verify a plaintext PIN against a stored bcrypt hash.
  bool _verifyPinSync(String pin, String storedHash) {
    try {
      return BCrypt.checkpw(pin, storedHash);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // NATIONAL ID ENCRYPTION (AES-256-GCM)
  // ============================================================

  /// Encrypts a National ID and returns "iv:ciphertext" base64-encoded.
  /// Returns null if input is null/empty.
  Future<String?> _encryptNationalId(String? plaintext) async {
    if (plaintext == null || plaintext.isEmpty) return null;
    final key = await _getAesKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Pack IV + ciphertext together so we can decrypt later
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a National ID. Returns null on any error or if input is null.
  Future<String?> _decryptNationalId(String? ciphertext) async {
    if (ciphertext == null || ciphertext.isEmpty) return null;
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return null;
      final key = await _getAesKey();
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // AUTH OPERATIONS
  // ============================================================

  @override
  Future<User> login(String phoneNumber, String? pin) async {
    try {
      final users = userBox.values.toList();

      Map<String, dynamic>? userData;
      for (final u in users) {
        if (u is Map && u['phoneNumber'] == phoneNumber) {
          userData = Map<String, dynamic>.from(u);
          break;
        }
      }

      if (userData == null) {
        throw const AuthException('User not found');
      }

      // PIN verification using bcrypt
      final storedHash = userData['pin'] as String?;
      if (storedHash != null && storedHash.isNotEmpty) {
        if (pin == null || pin.isEmpty) {
          throw const AuthException('PIN required');
        }
        final ok = _verifyPinSync(pin, storedHash);
        if (!ok) {
          throw const AuthException('Invalid PIN');
        }
      }

      final user = _userFromMap(userData);
      await saveUser(user.copyWith(lastLoginAt: DateTime.now()));
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<User> register({
    required String fullName,
    required String phoneNumber,
    String? nationalId,
    required UserRole role,
    String? pin,
  }) async {
    try {
      final existingUser = await isUserRegistered(phoneNumber);
      if (existingUser) {
        throw const AuthException('User already exists');
      }

      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Hash PIN with bcrypt (if provided)
      final hashedPin = (pin != null && pin.isNotEmpty)
          ? _hashPinSync(pin)
          : null;

      // Encrypt the National ID (if provided)
      final encryptedNid = await _encryptNationalId(nationalId);

      final user = User(
        id: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        nationalId: encryptedNid, // stored encrypted
        role: role,
        pin: hashedPin, // stored bcrypt-hashed
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await saveUser(user);
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await userBox.delete('current_user');
    } catch (e) {
      throw const CacheException('Failed to logout');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userData = userBox.get('current_user');
      if (userData == null) return null;
      return _userFromMap(Map<String, dynamic>.from(userData));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isUserRegistered(String phoneNumber) async {
    try {
      final users = userBox.values.toList();
      return users.any((u) {
        if (u is Map) return u['phoneNumber'] == phoneNumber;
        return false;
      });
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveUser(User user) async {
    await userBox.put(user.id, _userToMap(user));
    await userBox.put('current_user', _userToMap(user));
  }

  @override
  Future<bool> verifyPin({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final users = userBox.values.toList();
      Map<String, dynamic>? userData;
      for (final u in users) {
        if (u is Map && u['phoneNumber'] == phoneNumber) {
          userData = Map<String, dynamic>.from(u);
          break;
        }
      }
      if (userData == null) return false;

      final storedHash = userData['pin'] as String?;
      if (storedHash == null || storedHash.isEmpty) return false;

      return _verifyPinSync(pin, storedHash);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<User> changePin({
    required String userId,
    required String newPin,
  }) async {
    final stored = userBox.get(userId);
    if (stored == null) {
      throw const AuthException('User not found');
    }

    final userData = Map<String, dynamic>.from(stored as Map);
    final newHashedPin = _hashPinSync(newPin);
    userData['pin'] = newHashedPin;

    final updatedUser = _userFromMap(userData);
    await saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<String?> getDecryptedNationalId(String userId) async {
    final stored = userBox.get(userId);
    if (stored == null) return null;
    final userData = Map<String, dynamic>.from(stored as Map);
    final encrypted = userData['nationalId'] as String?;
    return _decryptNationalId(encrypted);
  }

  // ============================================================
  // MAPPING
  // ============================================================

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'], // stays encrypted in the entity
      role: UserRoleExtension.fromString(map['role'] ?? 'farmer'),
      pin: map['pin'], // stays hashed in the entity
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'])
          : null,
    );
  }

  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id,
      'fullName': user.fullName,
      'phoneNumber': user.phoneNumber,
      'nationalId': user.nationalId,
      'role': user.role.toStorageString(),
      'pin': user.pin,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt?.toIso8601String(),
    };
  }
}
