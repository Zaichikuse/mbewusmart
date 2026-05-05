import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/services/user_directory_service.dart';
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
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('Firebase is not initialized.');
    }
    final doc = db.collection('reports').doc();
    final report = DiagnosisReport(
      id: doc.id,
      farmerId: farmer.id,
      farmerName: farmer.fullName,
      farmerPhone: farmer.phoneNumber,
      cropType: diagnosis.cropType.name,
      diagnosisName: diagnosis.diagnosisName,
      confidence: diagnosis.confidence,
      latitude: location?.latitude ?? diagnosis.latitude,
      longitude: location?.longitude ?? diagnosis.longitude,
      placeName: location?.placeName ?? diagnosis.locationName,
      district: location?.district ?? farmer.district,
      imagePath: diagnosis.imagePath,
      timestamp: DateTime.now(),
      status: 'pending',
      extensionOfficerId: nearestOfficer?.id,
      notes: '',
    );

    await doc.set(report.toMap());
    await _notifyReportTargets(report, nearestOfficer);
    return report;
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

  Future<void> _notifyReportTargets(
    DiagnosisReport report,
    ExtensionOfficer? nearestOfficer,
  ) async {
    final managerTokens = await _userDirectoryService.getTokensByRole(
      UserRole.agricultureManager,
    );
    final officerToken = await _userDirectoryService.getNearestOfficerToken(
      officerId: nearestOfficer?.id,
      district: report.district,
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
          '${report.farmerName}: ${report.diagnosisName} (${(report.confidence * 100).toStringAsFixed(0)}%)',
      data: {
        'reportId': report.id,
        'farmerId': report.farmerId,
        'diagnosisName': report.diagnosisName,
        'confidence': report.confidence,
        'status': report.status,
      },
    );
  }
}
