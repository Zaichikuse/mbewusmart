import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/disease_trend_card.dart';
import '../repositories/disease_watch_repository.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';

class GetDiseaseTrendsByCropUseCase {
  final DiseaseWatchRepository repository;

  GetDiseaseTrendsByCropUseCase(this.repository);

  Future<Either<Failure, List<DiseaseTrendCard>>> call(
    String cropType, {
    DiagnosisCategory? category,
    int limitMonths = 1,
  }) async {
    return repository.getDiseaseTrendsByCrop(
      cropType,
      category: category,
      limitMonths: limitMonths,
    );
  }
}
