import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/scan_photo.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';

class DiseaseWatchCard extends StatelessWidget {
  final DiseaseTrendCard trend;
  final VoidCallback onTap;

  const DiseaseWatchCard({super.key, required this.trend, required this.onTap});

  Color _getCategoryColor(DiagnosisCategory category) {
    switch (category) {
      case DiagnosisCategory.pest:
        return AppTheme.accentOrange;
      case DiagnosisCategory.disease:
        return AppTheme.errorRed;
      case DiagnosisCategory.deficiency:
        return AppTheme.successGreen;
    }
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return AppTheme.healthyGreen;
      case Severity.medium:
        return AppTheme.warningAmber;
      case Severity.high:
        return AppTheme.accentOrange;
    }
  }

  String _getSeverityLabel(Severity severity) {
    switch (severity) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Moderate';
      case Severity.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if ((trend.photoBase64 ?? '').isNotEmpty ||
                  (trend.imageUrl ?? '').isNotEmpty)
                ScanPhoto(
                  base64Photo: trend.photoBase64,
                  legacyUrl: trend.imageUrl,
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(8),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppTheme.textMuted,
                  ),
                ),
              const SizedBox(width: 12),
              // Diagnosis name + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.diagnosisName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badges row
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(trend.category),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${trend.category.icon} ${trend.category.displayName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Severity badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(trend.severity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getSeverityLabel(trend.severity),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // District
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                trend.district,
                style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Treatment preview (2 lines)
          if ((trend.treatmentSummary != null &&
                  trend.treatmentSummary!.isNotEmpty) ||
              (trend.preventionSummary != null &&
                  trend.preventionSummary!.isNotEmpty))
            Text(
              [
                if (trend.treatmentSummary != null &&
                    trend.treatmentSummary!.isNotEmpty)
                  trend.treatmentSummary!,
                if (trend.preventionSummary != null &&
                    trend.preventionSummary!.isNotEmpty)
                  trend.preventionSummary!,
              ].join('\n\n'),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),
          // Footer: report count + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${trend.reportCount} report${trend.reportCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                timeAgoFromTimestamp(trend.recentReportDate),
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
