import 'package:equatable/equatable.dart';

enum UserRole {
  farmer,
  extensionOfficer,
  agricultureManager,
  agroDealer,
}

class User extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? nationalId;
  final UserRole role;
  final String? pin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // EPA and Location Information
  final String? epa;
  final String? district;
  final double? latitude;
  final double? longitude;

  const User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.nationalId,
    required this.role,
    this.pin,
    required this.createdAt,
    this.lastLoginAt,
    this.epa,
    this.district,
    this.latitude,
    this.longitude,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? nationalId,
    UserRole? role,
    String? pin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? epa,
    String? district,
    double? latitude,
    double? longitude,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      epa: epa ?? this.epa,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'role': role.toStorageString(),
      'pin': pin,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'epa': epa,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'],
      role: UserRoleExtension.fromString(map['role'] ?? 'farmer'),
      pin: map['pin'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.tryParse(map['lastLoginAt']) 
          : null,
      epa: map['epa'],
      district: map['district'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id, fullName, phoneNumber, nationalId, role, pin, 
    createdAt, lastLoginAt, epa, district, latitude, longitude
  ];
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.extensionOfficer:
        return 'Extension Officer';
      case UserRole.agricultureManager:
        return 'Agriculture Manager';
      case UserRole.agroDealer:
        return 'Agro-Dealer';
    }
  }

  String get displayNameChichewa {
    switch (this) {
      case UserRole.farmer:
        return 'Mlimi';
      case UserRole.extensionOfficer:
        return 'Afesa Officer';
      case UserRole.agricultureManager:
        return 'Manager Waulimi';
      case UserRole.agroDealer:
        return 'Agro-Dealer';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'farmer':
        return UserRole.farmer;
      case 'extension_officer':
        return UserRole.extensionOfficer;
      case 'agriculture_manager':
        return UserRole.agricultureManager;
      case 'agro_dealer':
        return UserRole.agroDealer;
      default:
        return UserRole.farmer;
    }
  }

  String toStorageString() {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.extensionOfficer:
        return 'extension_officer';
      case UserRole.agricultureManager:
        return 'agriculture_manager';
      case UserRole.agroDealer:
        return 'agro_dealer';
    }
  }
}