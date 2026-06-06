import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final String? country;
  final String? region;
  final String? district;
  final String? locality;
  final double latitude;
  final double longitude;

  const LocationData({
    this.country,
    this.region,
    this.district,
    this.locality,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    Placemark? placemark;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        placemark = placemarks.first;
      }
    } catch (_) {
      placemark = null;
    }

    return LocationData(
      country: placemark?.country,
      region: placemark?.administrativeArea,
      district: placemark?.subAdministrativeArea,
      locality: placemark?.locality ?? placemark?.subLocality,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
