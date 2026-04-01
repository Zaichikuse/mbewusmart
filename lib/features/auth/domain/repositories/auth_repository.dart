import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String phoneNumber, String? pin);
  Future<Either<Failure, User>> register({
    required String fullName,
    required String phoneNumber,
    String? nationalId,
    required UserRole role,
    String? pin,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, bool>> isUserRegistered(String phoneNumber);
}