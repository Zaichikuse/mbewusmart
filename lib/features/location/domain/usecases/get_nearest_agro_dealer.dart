import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/agro_dealer.dart';
import '../repositories/location_repository.dart';

class GetNearestAgroDealerUseCase {
  final LocationRepository repository;

  GetNearestAgroDealerUseCase(this.repository);

  Future<Either<Failure, AgroDealer>> call(double latitude, double longitude) async {
    return await repository.getNearestAgroDealer(latitude, longitude);
  }
}
