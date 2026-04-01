import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_local_datasource.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisLocalDataSource localDataSource;

  DiagnosisRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<DiagnosisResult>>> getHistory(String? userId) async {
    try {
      final history = await localDataSource.getHistory(userId);
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiagnosisResult>> saveDiagnosis(DiagnosisResult result) async {
    try {
      final saved = await localDataSource.saveDiagnosis(result);
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDiagnosis(String id) async {
    try {
      await localDataSource.deleteDiagnosis(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}