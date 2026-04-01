import 'package:equatable/equatable.dart';

class LocationInfo extends Equatable {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? district;
  final String? region;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.district,
    this.region,
  });

  @override
  List<Object?> get props => [latitude, longitude, placeName, district, region];
}
