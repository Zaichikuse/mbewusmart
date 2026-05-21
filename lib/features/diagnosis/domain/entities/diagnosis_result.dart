import 'package:equatable/equatable.dart';
import 'crop_type.dart';
import 'diagnosis_category.dart';

enum DiagnosisType { healthy, disease, pest, deficiency, unknown }

enum Severity { low, medium, high }

class DiagnosisResult extends Equatable {
  final String id;
  final String imagePath;
  final DiagnosisType type;
  final String diagnosisName;
  final String diagnosisNameChichewa;
  final double confidence;
  final Severity severity;
  final String? recommendation;
  final String? treatment;
  final String? prevention;
  final DateTime timestamp;
  final String? userId;
  final DiagnosisCategory? category;

  // New fields
  final CropType cropType;
  final String? scientificName;
  final String? causingFactors;
  final String? pesticideRemedy;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const DiagnosisResult({
    required this.id,
    required this.imagePath,
    required this.type,
    required this.diagnosisName,
    required this.diagnosisNameChichewa,
    required this.confidence,
    required this.severity,
    this.recommendation,
    this.treatment,
    this.prevention,
    required this.timestamp,
    this.userId,
    this.category,
    required this.cropType,
    this.scientificName,
    this.causingFactors,
    this.pesticideRemedy,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'type': type.name,
      'diagnosisName': diagnosisName,
      'diagnosisNameChichewa': diagnosisNameChichewa,
      'confidence': confidence,
      'severity': severity.name,
      'recommendation': recommendation,
      'treatment': treatment,
      'prevention': prevention,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'category': category?.name,
      'cropType': cropType.name,
      'scientificName': scientificName,
      'causingFactors': causingFactors,
      'pesticideRemedy': pesticideRemedy,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  factory DiagnosisResult.fromMap(Map<String, dynamic> map) {
    return DiagnosisResult(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      type: DiagnosisType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DiagnosisType.unknown,
      ),
      diagnosisName: map['diagnosisName'] ?? 'Unknown',
      diagnosisNameChichewa: map['diagnosisNameChichewa'] ?? 'Sodziwika',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      severity: Severity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => Severity.low,
      ),
      recommendation: map['recommendation'],
      treatment: map['treatment'],
      prevention: map['prevention'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      userId: map['userId'],
      category: map['category'] != null
          ? DiagnosisCategory.values.firstWhere(
              (e) => e.name == map['category'],
              orElse: () => DiagnosisCategory.disease,
            )
          : null,
      cropType: CropType.values.firstWhere(
        (e) => e.name == map['cropType'],
        orElse: () => CropType.maize,
      ),
      scientificName: map['scientificName'],
      causingFactors: map['causingFactors'],
      pesticideRemedy: map['pesticideRemedy'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
    );
  }

  DiagnosisResult copyWith({
    String? id,
    String? imagePath,
    DiagnosisType? type,
    String? diagnosisName,
    String? diagnosisNameChichewa,
    double? confidence,
    Severity? severity,
    String? recommendation,
    String? treatment,
    String? prevention,
    DateTime? timestamp,
    String? userId,
    DiagnosisCategory? category,
    CropType? cropType,
    String? scientificName,
    String? causingFactors,
    String? pesticideRemedy,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return DiagnosisResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      diagnosisName: diagnosisName ?? this.diagnosisName,
      diagnosisNameChichewa:
          diagnosisNameChichewa ?? this.diagnosisNameChichewa,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      recommendation: recommendation ?? this.recommendation,
      treatment: treatment ?? this.treatment,
      prevention: prevention ?? this.prevention,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      cropType: cropType ?? this.cropType,
      scientificName: scientificName ?? this.scientificName,
      causingFactors: causingFactors ?? this.causingFactors,
      pesticideRemedy: pesticideRemedy ?? this.pesticideRemedy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    imagePath,
    type,
    diagnosisName,
    diagnosisNameChichewa,
    confidence,
    severity,
    recommendation,
    treatment,
    prevention,
    timestamp,
    userId,
    category,
    cropType,
    scientificName,
    causingFactors,
    pesticideRemedy,
    latitude,
    longitude,
    locationName,
  ];
}

extension DiagnosisTypeExtension on DiagnosisType {
  String get displayName {
    switch (this) {
      case DiagnosisType.healthy:
        return 'Healthy';
      case DiagnosisType.disease:
        return 'Disease';
      case DiagnosisType.pest:
        return 'Pest';
      case DiagnosisType.deficiency:
        return 'Nutrient Deficiency';
      case DiagnosisType.unknown:
        return 'Unknown';
    }
  }

  String get displayNameChichewa {
    switch (this) {
      case DiagnosisType.healthy:
        return 'Kwauchipuka';
      case DiagnosisType.disease:
        return 'Matenda';
      case DiagnosisType.pest:
        return 'Khumani';
      case DiagnosisType.deficiency:
        return 'Vuto LA Chakudya';
      case DiagnosisType.unknown:
        return 'Sodziwika';
    }
  }
}

extension SeverityExtension on Severity {
  String get displayName {
    switch (this) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
    }
  }

  String get displayNameChichewa {
    switch (this) {
      case Severity.low:
        return 'Yochepa';
      case Severity.medium:
        return 'Ya Pakati';
      case Severity.high:
        return 'Yakulu';
    }
  }
}
