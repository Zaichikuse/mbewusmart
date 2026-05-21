import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/disease_watch_local_data_source.dart';
import '../datasources/disease_watch_remote_data_source.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/repositories/disease_watch_repository.dart';

class DiseaseWatchRepositoryImpl implements DiseaseWatchRepository {
  final DiseaseWatchRemoteDataSource remoteDataSource;
  final DiseaseWatchLocalDataSource localDataSource;

  DiseaseWatchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<DiseaseTrendCard>>> getDiseaseTrendsByCrop(
    String cropType, {
    DiagnosisCategory? category,
    int limitMonths = 1,
  }) async {
    try {
      // Fetch from Firebase (with is_public filter and PII stripping)
      final remoteResult = await remoteDataSource.getDiseaseTrendsByCrop(
        cropType,
        category: category?.name,
        page: 0,
        limit: 100,
      );

      final trends = await remoteResult.fold(
        (failure) async {
          // On failure, try to load from local cache
          try {
            final cachedTrends = await localDataSource.getTrendsByCategory(
              cropType,
              category,
            );
            return cachedTrends;
          } catch (_) {
            throw failure;
          }
        },
        (anonymizedTrends) async {
          // Convert AnonymizedDiseaseTrendDto to DiseaseTrendCard
          final converted = anonymizedTrends
              .map(
                (dto) => DiseaseTrendCard(
                  id: dto.id,
                  diagnosisName: dto.diagnosisName,
                  diagnosisNameChichewa:
                      dto.diagnosisName, // TODO: Store in database
                  category: _mapCategoryStringToEnum(dto.category),
                  severity: _mapSeverityStringToEnum(dto.severity),
                  district: dto.district,
                  reportCount: 1, // Anonymous aggregation doesn't expose counts
                  recentReportDate: dto.createdAt,
                  imageUrl: dto.photoUrl,
                  photoBase64: dto.photoBase64,
                  treatmentSummary: dto.treatmentAdvice,
                  preventionSummary: dto.preventionAdvice,
                  cropType: cropType,
                ),
              )
              .toList();

          // Cache locally for offline access
          await localDataSource.cacheTrends(cropType, converted);

          return converted;
        },
      );

      return Right(trends);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load disease trends: ${e.toString()}'),
      );
    }
  }

  /// Helper: Convert category string to enum.
  DiagnosisCategory _mapCategoryStringToEnum(String category) {
    switch (category.toLowerCase()) {
      case 'pest':
        return DiagnosisCategory.pest;
      case 'disease':
        return DiagnosisCategory.disease;
      case 'deficiency':
        return DiagnosisCategory.deficiency;
      default:
        return DiagnosisCategory.disease;
    }
  }

  /// Helper: Convert severity string to enum.
  Severity _mapSeverityStringToEnum(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Severity.high;
      case 'medium':
        return Severity.medium;
      case 'low':
        return Severity.low;
      default:
        return Severity.medium;
    }
  }
}
