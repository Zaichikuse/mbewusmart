import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/diagnosis_category_cache.dart';
import '../models/anonymized_disease_trend_dto.dart';
import '../serializers/disease_watch_serializer.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

/// Remote data source for Disease Watch feed from Firestore.
///
/// PRIVACY GUARANTEE: All queries filter by is_public=true and strip PII via serializer.
/// Indexes required (document in Firebase Console):
/// - (cropType, isPublic, timestamp DESC)
/// - (cropType, category, isPublic, timestamp DESC)
class DiseaseWatchRemoteDataSource {
  final FirebaseFirestore _firestore;
  final DiagnosisCategoryCache _categoryCache;

  DiseaseWatchRemoteDataSource({
    FirebaseFirestore? firestore,
    DiagnosisCategoryCache? categoryCache,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _categoryCache = categoryCache ?? DiagnosisCategoryCache();

  /// Get paginated, anonymized disease trends for a crop type.
  ///
  /// Filters:
  /// - cropType must match
  /// - is_public must be true (privacy-critical)
  /// - timestamp >= now - 30 days (monthly reports)
  /// - category optional filter
  ///
  /// Returns paginated results (limit 20 per page, sorted by timestamp DESC).
  Future<Either<Failure, List<AnonymizedDiseaseTrendDto>>>
  getDiseaseTrendsByCrop(
    String cropType, {
    String? category,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      // Calculate cutoff date (30 days ago)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      // Build query with filters
      Query query = _firestore
          .collection('reports')
          .where('crop', isEqualTo: cropType.toLowerCase())
          .where(
            'isPublic',
            isEqualTo: true,
          ) // PRIVACY: Only return public reports
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          );

      // Optional: filter by category
      if (category != null && category.isNotEmpty && category != 'all') {
        // Note: Category is stored on each report when saved.
        // This requires diagnosisName-to-category lookup or category field on report.
        // For now, we'll filter client-side after fetching (alternative: add category field to report).
        // TODO: Add category field to reports collection for efficient server-side filtering.
      }

      // Sort by most recent first
      query = query.orderBy('created_at', descending: true);

      // Paginate
      query = query.limit(limit + 1); // +1 to detect if more pages exist
      final snapshot = await query.get();

      // Fetch documents
      final reports = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return DiagnosisReport.fromMap(data);
      }).toList();

      final pageReports = reports.take(limit).toList();

      // Strip PII and fetch categories
      final anonymizedTrends = await Future.wait(
        pageReports.map((report) => _stripAndAnonymize(report)),
      );

      // Filter by category if specified (client-side filtering as temp workaround)
      final filtered =
          category != null && category.isNotEmpty && category != 'all'
          ? anonymizedTrends.where((t) => t.category == category).toList()
          : anonymizedTrends;

      return Right(filtered);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(CacheFailure('Error fetching disease trends: $e'));
    }
  }

  /// Get monthly report count for a crop type.
  /// Used for the banner: "X reports from farmers this month"
  Future<Either<Failure, int>> getMonthlyReportCount(String cropType) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('reports')
          .where('crop', isEqualTo: cropType.toLowerCase())
          .where('isPublic', isEqualTo: true)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .count()
          .get();

      return Right(snapshot.count ?? 0);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(CacheFailure('Error fetching count: $e'));
    }
  }

  /// Get category for a diagnosis name (with caching).
  /// Falls back to 'disease' if not found.
  Future<String> getCategoryForDiagnosis(String diagnosisName) async {
    // Check cache first
    final cached = _categoryCache.get(diagnosisName);
    if (cached != null) {
      return cached;
    }

    try {
      final doc = await _firestore
          .collection('diagnosis_categories')
          .doc(diagnosisName)
          .get();

      final category = doc.data()?['category'] as String? ?? 'disease';
      _categoryCache.set(diagnosisName, category);
      return category;
    } catch (e) {
      // Default to 'disease' on error
      print('[DiseaseWatchRemoteDataSource] Error fetching category: $e');
      return 'disease';
    }
  }

  /// Private helper: Strip PII from report and add category + treatment.
  Future<AnonymizedDiseaseTrendDto> _stripAndAnonymize(
    DiagnosisReport report,
  ) async {
    // Fetch category
    final category = await getCategoryForDiagnosis(report.diagnosisName);

    // Prefer the dedicated treatment/prevention fields written by scan save.
    final treatment = (report.treatment ?? '').trim().isNotEmpty
        ? report.treatment!.trim()
        : _extractTreatmentFromNotes(report.notes);
    final prevention = (report.prevention ?? '').trim();

    return DiseaseWatchSerializer.stripPii(
      report: report,
      category: category,
      treatment: treatment,
      prevention: prevention,
    );
  }

  String _extractTreatmentFromNotes(String notes) {
    if (notes.trim().isEmpty) return '';
    final lines = notes
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';
    return lines.join(' ');
  }
}
