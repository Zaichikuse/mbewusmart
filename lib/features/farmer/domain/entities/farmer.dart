import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

class Farmer extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? nationalId;
  final String district;
  final String? village;
  final List<String> cropsGrown;
  final double? farmSize;
  final String? farmSizeUnit;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const Farmer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.nationalId,
    required this.district,
    this.village,
    this.cropsGrown = const [],
    this.farmSize,
    this.farmSizeUnit,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory Farmer.fromUser(User user, {String? district, String? village, List<String>? cropsGrown, double? farmSize, String? farmSizeUnit}) {
    return Farmer(
      id: user.id,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      nationalId: user.nationalId,
      district: district ?? '',
      village: village,
      cropsGrown: cropsGrown ?? [],
      farmSize: farmSize,
      farmSizeUnit: farmSizeUnit,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  User toUser() {
    return User(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      nationalId: nationalId,
      role: UserRole.farmer,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'district': district,
      'village': village,
      'cropsGrown': cropsGrown,
      'farmSize': farmSize,
      'farmSizeUnit': farmSizeUnit,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory Farmer.fromMap(Map<String, dynamic> map) {
    return Farmer(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'],
      district: map['district'] ?? '',
      village: map['village'],
      cropsGrown: List<String>.from(map['cropsGrown'] ?? []),
      farmSize: map['farmSize']?.toDouble(),
      farmSizeUnit: map['farmSizeUnit'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt']) : null,
    );
  }

  Farmer copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? nationalId,
    String? district,
    String? village,
    List<String>? cropsGrown,
    double? farmSize,
    String? farmSizeUnit,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return Farmer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      district: district ?? this.district,
      village: village ?? this.village,
      cropsGrown: cropsGrown ?? this.cropsGrown,
      farmSize: farmSize ?? this.farmSize,
      farmSizeUnit: farmSizeUnit ?? this.farmSizeUnit,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        nationalId,
        district,
        village,
        cropsGrown,
        farmSize,
        farmSizeUnit,
        createdAt,
        lastLoginAt,
      ];
}
