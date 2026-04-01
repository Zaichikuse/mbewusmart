import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, User>> login(String phoneNumber, String? pin) async {
    try {
      final user = await localDataSource.login(phoneNumber, pin);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String fullName,
    required String phoneNumber,
    String? nationalId,
    required UserRole role,
    String? pin,
  }) async {
    try {
      final user = await localDataSource.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        nationalId: nationalId,
        role: role,
        pin: pin,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.logout();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, bool>> isUserRegistered(String phoneNumber) async {
    try {
      final result = await localDataSource.isUserRegistered(phoneNumber);
      return Right(result);
    } catch (e) {
      return const Right(false);
    }
  }
}