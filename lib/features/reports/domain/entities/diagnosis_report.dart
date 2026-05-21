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
  final String? photoBase64;
  final String? photoUrl;
  final String? treatment;
  final String? prevention;
  final DateTime timestamp;
  final String status;
  final String? extensionOfficerId;
  final String notes;
  final bool isPublic;

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
    this.photoBase64,
    this.photoUrl,
    this.treatment,
    this.prevention,
    required this.timestamp,
    required this.status,
    required this.extensionOfficerId,
    required this.notes,
    this.isPublic = true,
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
      'photo_base64': photoBase64,
      'photo_url': photoUrl,
      'treatment': treatment,
      'prevention': prevention,
      'timestamp': timestamp,
      'created_at': timestamp,
      'status': status,
      'extensionOfficerId': extensionOfficerId,
      'notes': notes,
      'isPublic': isPublic,
    };
  }

  factory DiagnosisReport.fromMap(Map<String, dynamic> map) {
    final imagePath = map['imagePath']?.toString() ?? '';
    final diagnosisName =
        map['diagnosis']?.toString() ?? map['diagnosisName']?.toString() ?? '';
    final cropType =
        map['crop']?.toString() ?? map['cropType']?.toString() ?? '';
    return DiagnosisReport(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      cropType: cropType,
      diagnosisName: diagnosisName,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeName: map['placeName'] ?? map['region'],
      district: map['district'] ?? map['region'],
      imagePath: imagePath,
      photoBase64: map['photo_base64'] ?? map['photoBase64'],
      photoUrl:
          map['photo_url'] ??
          map['photoUrl'] ??
          _legacyRemotePhotoUrl(imagePath),
      treatment: map['treatment'],
      prevention: map['prevention'],
      timestamp: _parseTimestamp(map['created_at'] ?? map['timestamp']),
      status: map['status'] ?? 'pending',
      extensionOfficerId: map['extensionOfficerId'],
      notes: map['notes'] ?? '',
      isPublic: map['isPublic'] ?? true,
    );
  }

  static String? _legacyRemotePhotoUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return null;
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
    photoBase64,
    photoUrl,
    treatment,
    prevention,
    timestamp,
    status,
    extensionOfficerId,
    notes,
    isPublic,
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
