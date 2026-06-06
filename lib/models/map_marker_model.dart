import 'package:latlong2/latlong.dart';

import '../features/reports/domain/entities/diagnosis_report.dart';

class MapMarker {
  final String reportId;
  final LatLng position;
  final String severity;
  final String diseaseName;
  final String region;
  final String district;
  final String locality;
  final String cropAffected;
  final String farmerName;
  final DateTime dateReported;

  const MapMarker({
    required this.reportId,
    required this.position,
    required this.severity,
    required this.diseaseName,
    required this.region,
    required this.district,
    required this.locality,
    required this.cropAffected,
    required this.farmerName,
    required this.dateReported,
  });

  static MapMarker? fromDiagnosisReport(DiagnosisReport report) {
    final lat = report.latitude;
    final lng = report.longitude;
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;

    return MapMarker(
      reportId: report.id,
      position: LatLng(lat, lng),
      severity: severityFromConfidence(report.confidence),
      diseaseName: report.diagnosisName,
      region: report.region ?? '',
      district: report.district ?? '',
      locality: (report.locality ?? report.placeName ?? '').trim(),
      cropAffected: report.cropType,
      farmerName: report.farmerName,
      dateReported: report.timestamp,
    );
  }

  static String severityFromConfidence(double confidence) {
    if (confidence >= 0.85) return 'high';
    if (confidence >= 0.70) return 'medium';
    return 'low';
  }
}
