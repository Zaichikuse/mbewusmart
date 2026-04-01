import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/diagnosis_result.dart';
import '../repositories/diagnosis_repository.dart';

class SaveDiagnosisUseCase {
  final DiagnosisRepository repository;

  SaveDiagnosisUseCase(this.repository);

  Future<Either<Failure, DiagnosisResult>> call(DiagnosisResult result) {
    return repository.saveDiagnosis(result);
  }
}