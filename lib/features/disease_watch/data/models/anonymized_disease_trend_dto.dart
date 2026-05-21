import 'package:equatable/equatable.dart';

/// Anonymized disease trend data for public Disease Watch display.
///
/// PRIVACY GUARANTEE: This DTO contains ONLY safe, non-identifying fields:
/// ✓ EXPOSED: id, photoUrl, diagnosisName, category, severity, district, treatmentAdvice, preventionAdvice, createdAt, createdAtRelative
/// ✗ NEVER EXPOSED: farmerId, farmerName, phone, email, latitude, longitude, placeName, notes
///
/// This entity is the output of PII stripping and should be the sole representation
/// returned by Disease Watch APIs and BLoCs.
class AnonymizedDiseaseTrendDto extends Equatable {
  final String id;
  final String photoUrl;
  final String? photoBase64;
  final String diagnosisName;
  final String category; // 'pest', 'disease', 'deficiency'
  final String severity; // 'low', 'medium', 'high'
  final String district;
  final String treatmentAdvice;
  final String preventionAdvice;
  final DateTime createdAt;
  final String createdAtRelative; // e.g., "2 days ago"

  const AnonymizedDiseaseTrendDto({
    required this.id,
    required this.photoUrl,
    this.photoBase64,
    required this.diagnosisName,
    required this.category,
    required this.severity,
    required this.district,
    required this.treatmentAdvice,
    required this.preventionAdvice,
    required this.createdAt,
    required this.createdAtRelative,
  });

  /// Convert to map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'diagnosisName': diagnosisName,
      'category': category,
      'severity': severity,
      'district': district,
      'treatmentAdvice': treatmentAdvice,
      'preventionAdvice': preventionAdvice,
      'createdAt': createdAt.toIso8601String(),
      'createdAtRelative': createdAtRelative,
    };
  }

  /// Create from map.
  factory AnonymizedDiseaseTrendDto.fromMap(Map<String, dynamic> map) {
    return AnonymizedDiseaseTrendDto(
      id: map['id'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      photoBase64: map['photoBase64'] ?? map['photo_base64'],
      diagnosisName: map['diagnosisName'] ?? '',
      category: map['category'] ?? 'disease',
      severity: map['severity'] ?? 'medium',
      district: map['district'] ?? '',
      treatmentAdvice: map['treatmentAdvice'] ?? '',
      preventionAdvice: map['preventionAdvice'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      createdAtRelative: map['createdAtRelative'] ?? 'recently',
    );
  }

  /// Copy with partial updates.
  AnonymizedDiseaseTrendDto copyWith({
    String? id,
    String? photoUrl,
    String? photoBase64,
    String? diagnosisName,
    String? category,
    String? severity,
    String? district,
    String? treatmentAdvice,
    String? preventionAdvice,
    DateTime? createdAt,
    String? createdAtRelative,
  }) {
    return AnonymizedDiseaseTrendDto(
      id: id ?? this.id,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      diagnosisName: diagnosisName ?? this.diagnosisName,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      district: district ?? this.district,
      treatmentAdvice: treatmentAdvice ?? this.treatmentAdvice,
      preventionAdvice: preventionAdvice ?? this.preventionAdvice,
      createdAt: createdAt ?? this.createdAt,
      createdAtRelative: createdAtRelative ?? this.createdAtRelative,
    );
  }

  @override
  List<Object?> get props => [
    id,
    photoUrl,
    photoBase64,
    diagnosisName,
    category,
    severity,
    district,
    treatmentAdvice,
    preventionAdvice,
    createdAt,
    createdAtRelative,
  ];
}
