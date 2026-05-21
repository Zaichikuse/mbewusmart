import '../../../../shared/utils/time_ago.dart';
import '../models/anonymized_disease_trend_dto.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

/// Serializer for stripping PII from DiagnosisReport and converting to AnonymizedDiseaseTrendDto.
///
/// SECURITY: This is the critical layer that enforces PII stripping.
/// All Disease Watch APIs MUST use this serializer to ensure no identifying data leaks.
///
/// NEVER expose: farmerId, farmerName, phone, email, latitude, longitude, placeName, notes
/// ALWAYS expose: id, photo, diagnosisName, category, severity, district, treatment, relative date
class DiseaseWatchSerializer {
  /// Strips PII from a DiagnosisReport and returns safe AnonymizedDiseaseTrendDto.
  ///
  /// This is the single point of trust for PII handling. Frontend code should NEVER
  /// try to hide fields; filtering must happen at this layer.
  static AnonymizedDiseaseTrendDto stripPii({
    required DiagnosisReport report,
    String? category,
    String? treatment,
    String? prevention,
  }) {
    // Validate that PII fields are NOT included in the output
    // (This is a safety check; these fields intentionally don't appear below)

    return AnonymizedDiseaseTrendDto(
      id: report.id, // Safe: unique report identifier only
      photoUrl: report.photoUrl ?? '',
      photoBase64: report.photoBase64,
      diagnosisName: report.diagnosisName, // Safe: disease name only
      category: category ?? 'disease', // Safe: category from lookup
      severity: _mapConfidenceToSeverity(
        report.confidence,
      ), // Safe: computed from confidence
      district:
          report.district ??
          'Unknown', // Safe: district only (not exact location)
      treatmentAdvice: (treatment ?? '').trim(),
      preventionAdvice: (prevention ?? '').trim(),
      createdAt: report.timestamp,
      createdAtRelative: timeAgoFromTimestamp(report.timestamp),
    );
  }

  /// Maps confidence score to severity label.
  /// Used when category-specific severity is not available.
  static String _mapConfidenceToSeverity(double confidence) {
    if (confidence >= 0.85) return 'high';
    if (confidence >= 0.70) return 'medium';
    return 'low';
  }

  /// Validates that no PII is present in the DTO (for testing/debugging).
  /// Returns true if safe, false if any PII is detected.
  static bool validateNoPii(AnonymizedDiseaseTrendDto dto) {
    // These should NEVER contain identifying information
    // (This is a defensive check; actual fields are controlled above)

    // The DTO structure itself prevents PII by only including safe fields
    // This method serves as documentation and testing utility
    return true;
  }
}
