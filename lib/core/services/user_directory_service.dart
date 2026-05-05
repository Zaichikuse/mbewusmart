import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/user.dart';

class UserDirectoryService {
  UserDirectoryService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  Future<void> syncUser(User user) async {
    final db = _db;
    if (db == null) return;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token while syncing user ${user.id}: $e');
      token = null;
    }
    try {
      await db.collection('users').doc(user.id).set({
        'id': user.id,
        'fullName': user.fullName,
        'phoneNumber': user.phoneNumber,
        'role': user.role.toStorageString(),
        'epa': user.epa,
        'district': user.district,
        'latitude': user.latitude,
        'longitude': user.longitude,
        'fcmToken': token,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to sync user ${user.id} to Firestore: $e');
    }
  }

  Future<String?> getFcmTokenForUserId(String userId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final snapshot = await db.collection('users').doc(userId).get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      final token = data['fcmToken'];
      return token is String && token.trim().isNotEmpty ? token : null;
    } catch (e) {
      debugPrint('Failed to read FCM token for user $userId: $e');
      return null;
    }
  }

  Future<List<String>> getTokensByRole(UserRole role) async {
    final db = _db;
    if (db == null) return const [];
    try {
      final snapshot = await db
          .collection('users')
          .where('role', isEqualTo: role.toStorageString())
          .get();

      return snapshot.docs
          .map((d) => d.data()['fcmToken'])
          .whereType<String>()
          .where((t) => t.trim().isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      debugPrint('Failed to read FCM tokens for role $role: $e');
      return const [];
    }
  }

  Future<String?> getNearestOfficerToken({
    String? officerId,
    String? district,
  }) async {
    if (officerId != null && officerId.trim().isNotEmpty) {
      return getFcmTokenForUserId(officerId);
    }

    if (district == null || district.trim().isEmpty) return null;

    final db = _db;
    if (db == null) return null;
    try {
      final snapshot = await db
          .collection('users')
          .where('role', isEqualTo: UserRole.extensionOfficer.toStorageString())
          .where('district', isEqualTo: district.trim())
          .get();

      for (final doc in snapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token is String && token.trim().isNotEmpty) {
          return token;
        }
      }

      return null;
    } catch (e) {
      debugPrint(
        'Failed to read nearest officer token for district $district: $e',
      );
      return null;
    }
  }
}
