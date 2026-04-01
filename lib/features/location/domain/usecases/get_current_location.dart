import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_info.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationUseCase {
  final LocationRepository repository;

  GetCurrentLocationUseCase(this.repository);

  Future<Either<Failure, LocationInfo>> call() async {
    return await repository.getCurrentLocation();
  }
}
