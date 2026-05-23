import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/anonymous_id_service.dart';
import '../../../../core/services/diagnosis_category_cache.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/services/pii_encryption_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../shared/utils/image_encoder.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../location/domain/entities/extension_officer.dart';
import '../../../location/domain/entities/location_info.dart';
import '../../domain/entities/diagnosis_report.dart';

class ReportService {
  ReportService({
    FirebaseFirestore? firestore,
    UserDirectoryService? userDirectoryService,
    FcmNotificationService? fcmNotificationService,
  }) : _firestore = firestore,
       _userDirectoryService = userDirectoryService ?? UserDirectoryService(),
       _fcmNotificationService =
           fcmNotificationService ?? FcmNotificationService();

  final FirebaseFirestore? _firestore;
  final UserDirectoryService _userDirectoryService;
  final FcmNotificationService _fcmNotificationService;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<DiagnosisReport>> watchReportsForOfficer(String officerId) {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection('reports')
        .where('extensionOfficerId', isEqualTo: officerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DiagnosisReport.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<DiagnosisReport>> watchAllReports() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection('reports')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DiagnosisReport.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<DiagnosisReport> createReport({
    required DiagnosisResult diagnosis,
    required User farmer,
    required LocationInfo? location,
    ExtensionOfficer? nearestOfficer,
    bool isPublic = true,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('Firebase is not initialized.');
    }

    if (farmer.id.trim().isEmpty) {
      throw Exception('Farmer ID missing. Please sign in again.');
    }

    // Get the anonymous device ID (NOT linked to phone/name)
    final anonId = await AnonymousIdService.getAnonymousId();

    final reportsDoc = db.collection('reports').doc();
    final diseaseWatchDoc = db.collection('disease_watch').doc(reportsDoc.id);

    // Encode photo
    String? photoBase64;
    try {
      final imageBytes = await _readScanImageBytes(diagnosis.imagePath);
      photoBase64 = await ImageEncoder.encodeForFirestore(imageBytes);
    } catch (e) {
      debugPrint('[ReportService] Photo encoding failed: $e');
    }

    final crop = diagnosis.cropType.name.toLowerCase();
    final district = AnonymousIdService.sanitizeDistrict(
      location?.district ?? farmer.district,
    );
    final treatmentText = diagnosis.treatment ?? diagnosis.recommendation ?? '';
    final preventionText = diagnosis.prevention ?? '';

    // 🔐 Encrypt PII before storing in the manager-only reports collection
    final encryptedName = await PiiEncryptionService.encryptString(
      farmer.fullName,
    );
    final encryptedPhone = await PiiEncryptionService.encryptString(
      farmer.phoneNumber,
    );

    // ============================================
    // COLLECTION 1: reports (manager-only, encrypted PII)
    // ============================================
    final reportData = <String, dynamic>{
      'crop': crop,
      'diagnosis': diagnosis.diagnosisName,
      'diagnosis_chichewa': diagnosis.diagnosisNameChichewa,
      'diagnosis_type': diagnosis.type.name,
      'severity': diagnosis.severity.name,
      'confidence': diagnosis.confidence,
      'symptoms': diagnosis.causingFactors ?? '',
      'causing_factors': diagnosis.causingFactors ?? '',
      'treatment': treatmentText,
      'prevention': preventionText,
      'photo_base64': photoBase64,
      'region': district ?? 'Unknown',
      'district': district,
      // 🔐 Anonymous ID instead of farmer.id
      'farmer_id': anonId,
      // 🔐 Name + phone are AES-256 encrypted
      'farmer_name_encrypted': encryptedName,
      'farmer_phone_encrypted': encryptedPhone,
      'created_at': FieldValue.serverTimestamp(),
      'extensionOfficerId': nearestOfficer?.id,
      'latitude': location?.latitude ?? diagnosis.latitude,
      'longitude': location?.longitude ?? diagnosis.longitude,
      'placeName': location?.placeName ?? diagnosis.locationName,
      'notes': [
        if (treatmentText.trim().isNotEmpty)
          'Treatment: ${treatmentText.trim()}',
        if (preventionText.trim().isNotEmpty)
          'Prevention: ${preventionText.trim()}',
      ].join('\n'),
      'photo_url': null,
      'isPublic': isPublic,
      'status': 'pending',
    };

    // ============================================
    // COLLECTION 2: disease_watch (public, ZERO PII)
    // ============================================
    final diseaseWatchData = <String, dynamic>{
      'crop': crop,
      'diagnosis': diagnosis.diagnosisName,
      'diagnosis_chichewa': diagnosis.diagnosisNameChichewa,
      'diagnosis_type': diagnosis.type.name,
      'severity': diagnosis.severity.name,
      'confidence': diagnosis.confidence,
      'district': district,
      // Coarse-grained coordinates (~11km precision) to prevent
      // pinpointing individual farms
      'latitude_approx': sanitizeCoordinate(
        location?.latitude ?? diagnosis.latitude,
      ),
      'longitude_approx': sanitizeCoordinate(
        location?.longitude ?? diagnosis.longitude,
      ),
      'created_at': FieldValue.serverTimestamp(),
      'isPublic': isPublic,
      // NOTE: NO name, NO phone, NO farmer_id, NO photo, NO exact location
    };

    // Write both docs in a batch (atomic — both succeed or neither)
    final batch = db.batch();
    batch.set(reportsDoc, reportData);
    if (isPublic) {
      batch.set(diseaseWatchDoc, diseaseWatchData);
    }
    await batch.commit();

    // Notify managers/officers (the notification doesn't include encrypted PII)
    await _notifyReportTargets(
      diagnosis,
      farmer.fullName,
      nearestOfficer,
      district ?? 'Unknown',
    );

    return DiagnosisReport(
      id: reportsDoc.id,
      farmerId: anonId,
      farmerName: farmer.fullName,
      farmerPhone: farmer.phoneNumber,
      cropType: crop,
      diagnosisName: diagnosis.diagnosisName,
      confidence: diagnosis.confidence,
      latitude: location?.latitude ?? diagnosis.latitude,
      longitude: location?.longitude ?? diagnosis.longitude,
      placeName: location?.placeName ?? diagnosis.locationName,
      district: district,
      imagePath: diagnosis.imagePath,
      photoBase64: photoBase64,
      photoUrl: null,
      treatment: treatmentText,
      prevention: preventionText,
      timestamp: DateTime.now(),
      status: 'pending',
      extensionOfficerId: nearestOfficer?.id,
      notes: reportData['notes'] as String,
      isPublic: isPublic,
    );
  }

  Future<Uint8List> _readScanImageBytes(String localPath) async {
    return File(localPath).readAsBytes();
  }

  Future<void> updateReportNotes({
    required String reportId,
    required String notes,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.collection('reports').doc(reportId).update({
      'notes': notes,
      'status': 'reviewed',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateReportPublicStatus({
    required String reportId,
    required bool isPublic,
  }) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    batch.update(db.collection('reports').doc(reportId), {
      'isPublic': isPublic,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    // Mirror change to disease_watch — delete or restore
    if (!isPublic) {
      batch.delete(db.collection('disease_watch').doc(reportId));
    }
    await batch.commit();
  }

  Future<String> getDiagnosisCategory(String diagnosisName) async {
    final cache = DiagnosisCategoryCache();
    final cached = cache.get(diagnosisName);
    if (cached != null) return cached;

    final db = _db;
    if (db == null) return 'disease';

    try {
      final doc = await db
          .collection('diagnosis_categories')
          .doc(diagnosisName)
          .get();
      final category = doc.data()?['category'] as String? ?? 'disease';
      cache.set(diagnosisName, category);
      return category;
    } catch (e) {
      debugPrint('[ReportService] Error fetching category: $e');
      return 'disease';
    }
  }

  Future<void> _notifyReportTargets(
    DiagnosisResult diagnosis,
    String farmerName,
    ExtensionOfficer? nearestOfficer,
    String farmerRegion,
  ) async {
    final managerTokens = await _userDirectoryService.getTokensByRole(
      UserRole.agricultureManager,
    );
    final officerToken = await _userDirectoryService.getNearestOfficerToken(
      officerId: nearestOfficer?.id,
      district: farmerRegion,
    );

    final tokens = <String>{...managerTokens};
    if (officerToken != null && officerToken.trim().isNotEmpty) {
      tokens.add(officerToken);
    }
    if (tokens.isEmpty) return;

    await _fcmNotificationService.sendToTokens(
      tokens: tokens.toList(),
      title: 'New Crop Report',
      body:
          'New ${diagnosis.diagnosisName} report (${(diagnosis.confidence * 100).toStringAsFixed(0)}%) in $farmerRegion',
      data: {
        'diagnosisName': diagnosis.diagnosisName,
        'confidence': diagnosis.confidence,
        'status': 'pending',
      },
    );
  }
}
