import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class SettingsRepository {
  Future<Either<Failure, String>> getLanguage();
  Future<Either<Failure, void>> setLanguage(String languageCode);
  Future<Either<Failure, bool>> getNotificationsEnabled();
  Future<Either<Failure, void>> setNotificationsEnabled(bool enabled);
  Future<Either<Failure, DateTime?>> getLastSyncTime();
  Future<Either<Failure, void>> setLastSyncTime(DateTime time);
}