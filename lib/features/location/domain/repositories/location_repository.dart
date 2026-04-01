import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_info.dart';
import '../entities/extension_officer.dart';
import '../entities/agro_dealer.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationInfo>> getCurrentLocation();
  Future<Either<Failure, ExtensionOfficer>> getNearestExtensionOfficer(double lat, double lng);
  Future<Either<Failure, AgroDealer>> getNearestAgroDealer(double lat, double lng);
  Future<Either<Failure, List<ExtensionOfficer>>> getAllExtensionOfficers();
  Future<Either<Failure, List<AgroDealer>>> getAllAgroDealers();
  Future<Either<Failure, String>> getLocationName(double lat, double lng);
}
