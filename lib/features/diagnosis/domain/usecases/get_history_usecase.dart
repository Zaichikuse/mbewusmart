import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/diagnosis_result.dart';
import '../repositories/diagnosis_repository.dart';

class GetHistoryUseCase {
  final DiagnosisRepository repository;

  GetHistoryUseCase(this.repository);

  Future<Either<Failure, List<DiagnosisResult>>> call(String? userId) {
    return repository.getHistory(userId);
  }
}