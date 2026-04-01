import 'dart:math';
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
        return const Left(LocationFailure('Location permissions are permanently denied'));
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
          placeName = placemark.subAdministrativeArea ?? placemark.administrativeArea;
          district = placemark.administrativeArea;
        }
      } catch (e) {
        // Geocoding failed, try to match with Malawi districts
        district = _findNearestDistrict(position.latitude, position.longitude);
        placeName = district;
      }

      return Right(LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: placeName,
        district: district,
        region: 'Malawi',
      ));
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
      final officers = malawiDataSource.getAllExtensionOfficers();
      if (officers.isEmpty) {
        return const Left(LocationFailure('No extension officers available'));
      }

      ExtensionOfficer nearest = officers.first;
      double minDistance = double.infinity;

      for (final officer in officers) {
        double distance = _calculateDistance(lat, lng, officer.latitude, officer.longitude);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = officer;
        }
      }

      return Right(nearest);
    } catch (e) {
      return Left(LocationFailure('Failed to find nearest officer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AgroDealer>> getNearestAgroDealer(double lat, double lng) async {
    try {
      final dealers = malawiDataSource.getAllAgroDealers();
      if (dealers.isEmpty) {
        return const Left(LocationFailure('No agro-dealers available'));
      }

      AgroDealer nearest = dealers.first;
      double minDistance = double.infinity;

      for (final dealer in dealers) {
        double distance = _calculateDistance(lat, lng, dealer.latitude, dealer.longitude);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = dealer;
        }
      }

      return Right(nearest);
    } catch (e) {
      return Left(LocationFailure('Failed to find nearest dealer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ExtensionOfficer>>> getAllExtensionOfficers() async {
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
  Future<Either<Failure, String>> getLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final name = placemark.subAdministrativeArea ?? 
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
        lat, lng,
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

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
