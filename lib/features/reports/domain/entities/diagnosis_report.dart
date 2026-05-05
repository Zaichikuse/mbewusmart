import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DiagnosisReport extends Equatable {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String cropType;
  final String diagnosisName;
  final double confidence;
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? district;
  final String imagePath;
  final DateTime timestamp;
  final String status;
  final String? extensionOfficerId;
  final String notes;

  const DiagnosisReport({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.cropType,
    required this.diagnosisName,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.district,
    required this.imagePath,
    required this.timestamp,
    required this.status,
    required this.extensionOfficerId,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'cropType': cropType,
      'diagnosisName': diagnosisName,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'district': district,
      'imagePath': imagePath,
      'timestamp': timestamp,
      'status': status,
      'extensionOfficerId': extensionOfficerId,
      'notes': notes,
    };
  }

  factory DiagnosisReport.fromMap(Map<String, dynamic> map) {
    return DiagnosisReport(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      cropType: map['cropType'] ?? '',
      diagnosisName: map['diagnosisName'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeName: map['placeName'],
      district: map['district'],
      imagePath: map['imagePath'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      status: map['status'] ?? 'pending',
      extensionOfficerId: map['extensionOfficerId'],
      notes: map['notes'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    farmerId,
    farmerName,
    farmerPhone,
    cropType,
    diagnosisName,
    confidence,
    latitude,
    longitude,
    placeName,
    district,
    imagePath,
    timestamp,
    status,
    extensionOfficerId,
    notes,
  ];
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}
