import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/extension_officer.dart';
import '../repositories/location_repository.dart';

class GetNearestExtensionOfficerUseCase {
  final LocationRepository repository;

  GetNearestExtensionOfficerUseCase(this.repository);

  Future<Either<Failure, ExtensionOfficer>> call(double latitude, double longitude) async {
    return await repository.getNearestExtensionOfficer(latitude, longitude);
  }
}
