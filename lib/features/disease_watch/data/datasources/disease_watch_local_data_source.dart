import 'package:hive/hive.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';

abstract class DiseaseWatchLocalDataSource {
  Future<void> cacheTrends(String cropType, List<DiseaseTrendCard> trends);
  Future<List<DiseaseTrendCard>> getTrendsByCategory(
    String cropType,
    DiagnosisCategory? category,
  );
  Future<void> clearCache();
}

class DiseaseWatchLocalDataSourceImpl implements DiseaseWatchLocalDataSource {
  final Box diseaseWatchBox;

  DiseaseWatchLocalDataSourceImpl(this.diseaseWatchBox);

  @override
  Future<void> cacheTrends(
    String cropType,
    List<DiseaseTrendCard> trends,
  ) async {
    try {
      final trendsMaps = trends.map((t) => t.toMap()).toList();
      await diseaseWatchBox.put(cropType, trendsMaps);
    } catch (e) {
      // Silently fail on cache write — not critical
      print('DiseaseWatch cache write error: $e');
    }
  }

  @override
  Future<List<DiseaseTrendCard>> getTrendsByCategory(
    String cropType,
    DiagnosisCategory? category,
  ) async {
    try {
      final cached = diseaseWatchBox.get(cropType);
      if (cached == null) return [];

      final list = (cached as List).cast<Map<dynamic, dynamic>>();
      final trends = list
          .map(
            (item) => DiseaseTrendCard.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();

      // Apply category filter if specified
      if (category != null) {
        return trends.where((t) => t.category == category).toList();
      }

      return trends;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await diseaseWatchBox.clear();
    } catch (e) {
      print('DiseaseWatch cache clear error: $e');
    }
  }
}
