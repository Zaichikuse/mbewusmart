import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../../../../shared/widgets/scan_photo.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

class DiseaseDetailBottomSheet extends StatelessWidget {
  final DiseaseTrendCard trend;

  const DiseaseDetailBottomSheet({super.key, required this.trend});

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
    final hasTreatment = (trend.treatmentSummary ?? '').trim().isNotEmpty;
    final hasPrevention = (trend.preventionSummary ?? '').trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo
                  if ((trend.photoBase64 ?? '').isNotEmpty ||
                      (trend.imageUrl ?? '').isNotEmpty)
                    ScanPhoto(
                      base64Photo: trend.photoBase64,
                      legacyUrl: trend.imageUrl,
                      width: double.infinity,
                      height: 240,
                      borderRadius: BorderRadius.circular(12),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Diagnosis name
                  Text(
                    trend.diagnosisName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category & Severity badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(trend.category),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${trend.category.icon} ${trend.category.displayName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Severity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(trend.severity),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getSeverityLabel(trend.severity),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // District
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trend.district,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Report stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trend.reportCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const Text(
                              'Total Reports',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeAgoFromTimestamp(trend.recentReportDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Text(
                              'Latest Report',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Treatment advice
                  const Text(
                    'Treatment & Prevention',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!hasTreatment && !hasPrevention)
                    Text(
                      'No treatment information available yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTreatment) ...[
                          const Text(
                            'Treatment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            trend.treatmentSummary!.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textDark,
                              height: 1.6,
                            ),
                          ),
                          if (hasPrevention) const SizedBox(height: 16),
                        ],
                        if (hasPrevention) ...[
                          const Text(
                            'Prevention',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            trend.preventionSummary!.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textDark,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
