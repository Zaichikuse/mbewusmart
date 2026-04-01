import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, String>> getLanguage() async {
    try {
      final language = await localDataSource.getLanguage();
      return Right(language);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setLanguage(String languageCode) async {
    try {
      await localDataSource.setLanguage(languageCode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getNotificationsEnabled() async {
    try {
      final enabled = await localDataSource.getNotificationsEnabled();
      return Right(enabled);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, void>> setNotificationsEnabled(bool enabled) async {
    try {
      await localDataSource.setNotificationsEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime() async {
    try {
      final time = await localDataSource.getLastSyncTime();
      return Right(time);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> setLastSyncTime(DateTime time) async {
    try {
      await localDataSource.setLastSyncTime(time);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}