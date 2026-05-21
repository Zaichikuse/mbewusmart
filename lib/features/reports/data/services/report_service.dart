import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/diagnosis_category_cache.dart';
import '../../../../core/services/fcm_notification_service.dart';
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
        .orderBy('timestamp', descending: true)
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
        .orderBy('timestamp', descending: true)
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

    // FIX: Use the farmer passed in from ScanPage's AuthBloc instead of
    // checking FirebaseAuth.instance.currentUser. The two auth sources
    // can drift out of sync, but AuthBloc is the source of truth in this
    // app because that's what ScanPage already validated.
    if (farmer.id.trim().isEmpty) {
      throw Exception('Farmer ID missing. Please sign in again.');
    }

    final doc = db.collection('reports').doc();

    String? photoBase64;
    try {
      final imageBytes = await _readScanImageBytes(diagnosis.imagePath);
      photoBase64 = await ImageEncoder.encodeForFirestore(imageBytes);
      debugPrint(
        '[ReportService] Encoded photo size: ${photoBase64.length} chars (~${(photoBase64.length * 0.75 / 1024).toStringAsFixed(0)} KB)',
      );
    } catch (e) {
      debugPrint('[ReportService] Photo encoding failed: $e');
    }

    final crop = diagnosis.cropType.name;
    final farmerRegion = location?.district ?? farmer.district ?? 'Unknown';
    final treatmentText = diagnosis.treatment ?? diagnosis.recommendation ?? '';
    final preventionText = diagnosis.prevention ?? '';
    final reportData = {
      'crop': crop.toLowerCase(),
      'diagnosis': diagnosis.diagnosisName,
      'diagnosis_chichewa': diagnosis.diagnosisNameChichewa,
      'diagnosis_type': diagnosis.type.name,
      'severity': diagnosis.severity.name,
      'confidence': diagnosis.confidence,
      'symptoms': diagnosis.causingFactors ?? diagnosis.recommendation ?? '',
      'causing_factors': diagnosis.causingFactors ?? '',
      'treatment': treatmentText,
      'prevention': preventionText,
      'photo_base64': photoBase64,
      'region': farmerRegion,
      'farmer_id': farmer.id,
      'farmer_name': farmer.fullName,
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
    };

    await doc.set(reportData);
    await _notifyReportTargets(
      diagnosis,
      farmer.fullName,
      nearestOfficer,
      farmerRegion,
    );
    return DiagnosisReport(
      id: doc.id,
      farmerId: farmer.id,
      farmerName: farmer.fullName,
      farmerPhone: farmer.phoneNumber,
      cropType: crop,
      diagnosisName: diagnosis.diagnosisName,
      confidence: diagnosis.confidence,
      latitude: location?.latitude ?? diagnosis.latitude,
      longitude: location?.longitude ?? diagnosis.longitude,
      placeName: location?.placeName ?? diagnosis.locationName,
      district: farmerRegion,
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

  /// Update the is_public flag for a report.
  /// When set to false, the report will NOT appear in Disease Watch
  /// but will still be visible to the Agriculture Manager.
  Future<void> updateReportPublicStatus({
    required String reportId,
    required bool isPublic,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.collection('reports').doc(reportId).update({
      'isPublic': isPublic,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get the category for a diagnosis name (with caching).
  /// Queries the diagnosis_categories Firestore collection.
  /// Falls back to 'disease' if not found.
  Future<String> getDiagnosisCategory(String diagnosisName) async {
    final cache = DiagnosisCategoryCache();

    final cached = cache.get(diagnosisName);
    if (cached != null) {
      return cached;
    }

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
          '$farmerName: ${diagnosis.diagnosisName} (${(diagnosis.confidence * 100).toStringAsFixed(0)}%)',
      data: {
        'diagnosisName': diagnosis.diagnosisName,
        'confidence': diagnosis.confidence,
        'status': 'pending',
      },
    );
  }
}
