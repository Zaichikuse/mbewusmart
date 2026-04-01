import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/diagnosis_result.dart';

abstract class DiagnosisRepository {
  Future<Either<Failure, List<DiagnosisResult>>> getHistory(String? userId);
  Future<Either<Failure, DiagnosisResult>> saveDiagnosis(DiagnosisResult result);
  Future<Either<Failure, void>> deleteDiagnosis(String id);
}