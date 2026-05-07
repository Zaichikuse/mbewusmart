import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final String id;
  final String farmerName;
  final String farmerPhone;
  final String location;
  final String district;
  final String cropName;
  final String diagnosisName;
  final double confidence;
  final DateTime timestamp;
  final String note;
  final bool isRead;
  final String status;
  final String? officerResponse;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const Alert({
    required this.id,
    required this.farmerName,
    required this.farmerPhone,
    required this.location,
    this.district = '',
    required this.cropName,
    required this.diagnosisName,
    required this.confidence,
    required this.timestamp,
    required this.note,
    this.isRead = false,
    this.status = 'pending',
    this.officerResponse,
    this.respondedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  Alert copyWith({
    String? id,
    String? farmerName,
    String? farmerPhone,
    String? location,
    String? district,
    String? cropName,
    String? diagnosisName,
    double? confidence,
    DateTime? timestamp,
    String? note,
    bool? isRead,
    String? status,
    String? officerResponse,
    DateTime? respondedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return Alert(
      id: id ?? this.id,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      location: location ?? this.location,
      district: district ?? this.district,
      cropName: cropName ?? this.cropName,
      diagnosisName: diagnosisName ?? this.diagnosisName,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      officerResponse: officerResponse ?? this.officerResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'location': location,
      'district': district,
      'cropName': cropName,
      'diagnosisName': diagnosisName,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'isRead': isRead,
      'status': status,
      'officerResponse': officerResponse,
      'respondedAt': respondedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      location: map['location'] ?? '',
      district: map['district'] ?? '',
      cropName: map['cropName'] ?? '',
      diagnosisName: map['diagnosisName'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      note: map['note'] ?? '',
      isRead: map['isRead'] ?? false,
      status: map['status'] ?? 'pending',
      officerResponse: map['officerResponse'],
      respondedAt: map['respondedAt'] != null
          ? DateTime.tryParse(map['respondedAt'])
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'])
          : null,
      resolvedBy: map['resolvedBy'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    farmerName,
    farmerPhone,
    location,
    district,
    cropName,
    diagnosisName,
    confidence,
    timestamp,
    note,
    isRead,
    status,
    officerResponse,
    respondedAt,
    resolvedAt,
    resolvedBy,
  ];
}
