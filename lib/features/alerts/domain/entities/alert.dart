import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final String id;
  final String farmerName;
  final String farmerPhone;
  final String location;
  final String cropName;
  final String diagnosisName;
  final double confidence;
  final DateTime timestamp;
  final String note;
  final bool isRead;
  final String? officerResponse;
  final DateTime? respondedAt;

  const Alert({
    required this.id,
    required this.farmerName,
    required this.farmerPhone,
    required this.location,
    required this.cropName,
    required this.diagnosisName,
    required this.confidence,
    required this.timestamp,
    required this.note,
    this.isRead = false,
    this.officerResponse,
    this.respondedAt,
  });

  Alert copyWith({
    String? id,
    String? farmerName,
    String? farmerPhone,
    String? location,
    String? cropName,
    String? diagnosisName,
    double? confidence,
    DateTime? timestamp,
    String? note,
    bool? isRead,
    String? officerResponse,
    DateTime? respondedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      location: location ?? this.location,
      cropName: cropName ?? this.cropName,
      diagnosisName: diagnosisName ?? this.diagnosisName,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      isRead: isRead ?? this.isRead,
      officerResponse: officerResponse ?? this.officerResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'location': location,
      'cropName': cropName,
      'diagnosisName': diagnosisName,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'isRead': isRead,
      'officerResponse': officerResponse,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      location: map['location'] ?? '',
      cropName: map['cropName'] ?? '',
      diagnosisName: map['diagnosisName'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      note: map['note'] ?? '',
      isRead: map['isRead'] ?? false,
      officerResponse: map['officerResponse'],
      respondedAt: map['respondedAt'] != null ? DateTime.tryParse(map['respondedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [
    id, farmerName, farmerPhone, location, cropName, 
    diagnosisName, confidence, timestamp, note, isRead, 
    officerResponse, respondedAt
  ];
}
