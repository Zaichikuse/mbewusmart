import 'package:equatable/equatable.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

class DiseaseTrendCard extends Equatable {
  final String id;
  final String diagnosisName;
  final String diagnosisNameChichewa;
  final DiagnosisCategory category;
  final Severity severity;
  final String district;
  final int reportCount;
  final DateTime recentReportDate;
  final String? imageUrl;
  final String? photoBase64;
  final String? treatmentSummary;
  final String? preventionSummary;
  final String cropType;

  const DiseaseTrendCard({
    required this.id,
    required this.diagnosisName,
    required this.diagnosisNameChichewa,
    required this.category,
    required this.severity,
    required this.district,
    required this.reportCount,
    required this.recentReportDate,
    this.imageUrl,
    this.photoBase64,
    this.treatmentSummary,
    this.preventionSummary,
    required this.cropType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diagnosisName': diagnosisName,
      'diagnosisNameChichewa': diagnosisNameChichewa,
      'category': category.name,
      'severity': severity.name,
      'district': district,
      'reportCount': reportCount,
      'recentReportDate': recentReportDate.toIso8601String(),
      'imageUrl': imageUrl,
      'photoBase64': photoBase64,
      'treatmentSummary': treatmentSummary,
      'preventionSummary': preventionSummary,
      'cropType': cropType,
    };
  }

  factory DiseaseTrendCard.fromMap(Map<String, dynamic> map) {
    return DiseaseTrendCard(
      id: map['id'] ?? '',
      diagnosisName: map['diagnosisName'] ?? 'Unknown',
      diagnosisNameChichewa: map['diagnosisNameChichewa'] ?? 'Sodziwika',
      category: DiagnosisCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => DiagnosisCategory.disease,
      ),
      severity: Severity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => Severity.low,
      ),
      district: map['district'] ?? '',
      reportCount: map['reportCount'] ?? 1,
      recentReportDate:
          DateTime.tryParse(map['recentReportDate'] ?? '') ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      photoBase64: map['photoBase64'] ?? map['photo_base64'],
      treatmentSummary: map['treatmentSummary'],
      preventionSummary: map['preventionSummary'],
      cropType: map['cropType'] ?? '',
    );
  }

  DiseaseTrendCard copyWith({
    String? id,
    String? diagnosisName,
    String? diagnosisNameChichewa,
    DiagnosisCategory? category,
    Severity? severity,
    String? district,
    int? reportCount,
    DateTime? recentReportDate,
    String? imageUrl,
    String? photoBase64,
    String? treatmentSummary,
    String? preventionSummary,
    String? cropType,
  }) {
    return DiseaseTrendCard(
      id: id ?? this.id,
      diagnosisName: diagnosisName ?? this.diagnosisName,
      diagnosisNameChichewa:
          diagnosisNameChichewa ?? this.diagnosisNameChichewa,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      district: district ?? this.district,
      reportCount: reportCount ?? this.reportCount,
      recentReportDate: recentReportDate ?? this.recentReportDate,
      imageUrl: imageUrl ?? this.imageUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      treatmentSummary: treatmentSummary ?? this.treatmentSummary,
      preventionSummary: preventionSummary ?? this.preventionSummary,
      cropType: cropType ?? this.cropType,
    );
  }

  @override
  List<Object?> get props => [
    id,
    diagnosisName,
    diagnosisNameChichewa,
    category,
    severity,
    district,
    reportCount,
    recentReportDate,
    imageUrl,
    photoBase64,
    treatmentSummary,
    preventionSummary,
    cropType,
  ];
}
