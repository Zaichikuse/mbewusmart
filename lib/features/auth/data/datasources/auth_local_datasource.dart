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
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box userBox;

  AuthLocalDataSourceImpl(this.userBox);

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

      if (userData['pin'] != null && userData['pin'] != pin) {
        throw const AuthException('Invalid PIN');
      }

      final user = _userFromMap(userData);
      await saveUser(user.copyWith(lastLoginAt: DateTime.now()));
      return user;
    } catch (e) {
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
      final user = User(
        id: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        nationalId: nationalId,
        role: role,
        pin: pin,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await saveUser(user);
      return user;
    } catch (e) {
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
        if (u is Map) {
          return u['phoneNumber'] == phoneNumber;
        }
        return false;
      });
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveUser(User user) async {
    await userBox.put(user.id, _userToMap(user));
    await userBox.put('current_user', _userToMap(user));
  }

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'],
      role: UserRoleExtension.fromString(map['role'] ?? 'farmer'),
      pin: map['pin'],
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