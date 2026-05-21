import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/disease_trend_card.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';

abstract class DiseaseWatchRepository {
  Future<Either<Failure, List<DiseaseTrendCard>>> getDiseaseTrendsByCrop(
    String cropType, {
    DiagnosisCategory? category,
    int limitMonths = 1,
  });
}
