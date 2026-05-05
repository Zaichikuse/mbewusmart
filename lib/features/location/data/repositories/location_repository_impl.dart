import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/entities/extension_officer.dart';
import '../../domain/entities/agro_dealer.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/malawi_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final MalawiDataSource malawiDataSource;

  LocationRepositoryImpl({required this.malawiDataSource});

  // ── Class-level distance calculator ───────────────────────────────
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  @override
  Future<Either<Failure, LocationInfo>> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(LocationFailure('Location services are disabled'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(LocationFailure('Location permissions are denied'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(
          LocationFailure('Location permissions are permanently denied'),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? placeName;
      String? district;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          placeName =
              placemark.subAdministrativeArea ?? placemark.administrativeArea;
          district = placemark.administrativeArea;
        }
      } catch (e) {
        district = _findNearestDistrict(position.latitude, position.longitude);
        placeName = district;
      }

      return Right(
        LocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
          placeName: placeName,
          district: district,
          region: 'Malawi',
        ),
      );
    } catch (e) {
      return Left(LocationFailure('Failed to get location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExtensionOfficer>> getNearestExtensionOfficer(
    double lat,
    double lng,
  ) async {
    try {
      final nearest = malawiDataSource.getNearestExtensionOfficer(lat, lng);
      if (nearest == null) {
        return const Left(LocationFailure('No extension officers available'));
      }
      return Right(nearest);
    } catch (e) {
      return Left(
        LocationFailure('Failed to find nearest officer: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, AgroDealer>> getNearestAgroDealer(
    double lat,
    double lng,
  ) async {
    try {
      final nearest = malawiDataSource.getNearestAgroDealer(lat, lng);
      if (nearest == null) {
        return const Left(LocationFailure('No agro-dealers available'));
      }
      return Right(nearest);
    } catch (e) {
      return Left(
        LocationFailure('Failed to find nearest dealer: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ExtensionOfficer>>>
  getAllExtensionOfficers() async {
    try {
      return Right(malawiDataSource.getAllExtensionOfficers());
    } catch (e) {
      return Left(LocationFailure('Failed to get officers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AgroDealer>>> getAllAgroDealers() async {
    try {
      return Right(malawiDataSource.getAllAgroDealers());
    } catch (e) {
      return Left(LocationFailure('Failed to get dealers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getLocationName(
    double lat,
    double lng,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final name =
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            'Unknown';
        return Right(name);
      }
      return const Right('Unknown Location');
    } catch (e) {
      final district = _findNearestDistrict(lat, lng);
      return Right(district);
    }
  }

  String _findNearestDistrict(double lat, double lng) {
    String nearestDistrict = 'Blantyre';
    double minDistance = double.infinity;

    for (final entry in MalawiDataSource.districts.entries) {
      double distance = _calculateDistance(
        lat,
        lng,
        entry.value['lat']!,
        entry.value['lng']!,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestDistrict = entry.key;
      }
    }

    return nearestDistrict;
  }
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
