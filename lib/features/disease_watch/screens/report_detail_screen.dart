import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../reports/data/services/report_service.dart';
import '../../reports/domain/entities/diagnosis_report.dart';
import '../../../shared/widgets/scan_photo.dart';
import '../widgets/comments_section.dart';
import '../widgets/location_card.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reportService = di.sl<ReportService>();
    final appLoc = AppLocalizations.of(context);

    if (reportId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLoc?.translate('reportDetails') ?? 'Report Details'),
        ),
        body: Center(
          child: Text(
            appLoc?.translate('reportUnavailable') ?? 'Report unavailable',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(appLoc?.translate('reportDetails') ?? 'Report Details'),
      ),
      body: StreamBuilder<DiagnosisReport?>(
        stream: reportService.watchReportById(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return Center(
              child: Text(
                appLoc?.translate('reportUnavailable') ?? 'Report unavailable',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          final hasTreatment = (report.treatment ?? '').trim().isNotEmpty;
          final hasPrevention = (report.prevention ?? '').trim().isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((report.photoBase64 ?? '').isNotEmpty ||
                            (report.photoUrl ?? '').isNotEmpty)
                          ScanPhoto(
                            base64Photo: report.photoBase64,
                            legacyUrl: report.photoUrl,
                            height: 240,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          report.diagnosisName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LocationCard(
                          region: report.region,
                          district: report.district,
                          locality: report.locality,
                        ),
                        const SizedBox(height: 16),
                        if (hasTreatment) ...[
                          Text(
                            appLoc?.translate('treatment') ?? 'Treatment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.treatment!.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (hasPrevention) ...[
                          Text(
                            appLoc?.translate('prevention') ?? 'Prevention',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.prevention!.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(flex: 6, child: CommentsSection(reportId: reportId)),
              ],
            ),
          );
        },
      ),
    );
  }
}
