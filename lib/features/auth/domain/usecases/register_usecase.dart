import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String fullName,
    required String phoneNumber,
    String? nationalId,
    required UserRole role,
    String? pin,
  }) {
    return repository.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      nationalId: nationalId,
      role: role,
      pin: pin,
    );
  }
}