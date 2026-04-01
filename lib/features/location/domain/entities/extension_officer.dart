import 'package:equatable/equatable.dart';

class ExtensionOfficer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String district;
  final String? area;
  final double latitude;
  final double longitude;
  
  // EPA Information
  final String? epa;
  final String? region;

  const ExtensionOfficer({
    required this.id,
    required this.name,
    required this.phone,
    required this.district,
    this.area,
    required this.latitude,
    required this.longitude,
    this.epa,
    this.region,
  });

  @override
  List<Object?> get props => [
    id, name, phone, district, area, latitude, longitude, epa, region
  ];
}
