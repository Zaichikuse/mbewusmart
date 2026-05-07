import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

// Kept for backward compatibility — dashboard still passes this enum,
// but we no longer filter by status (diagnoses are historical records).
enum ManagerReportsFilter { allDiagnoses, pendingOnly, reviewedOnly }

class ManagerReportsPage extends StatefulWidget {
  final ManagerReportsFilter initialFilter;
  final String? initialDistrict;

  const ManagerReportsPage({
    super.key,
    this.initialFilter = ManagerReportsFilter.allDiagnoses,
    this.initialDistrict,
  });

  @override
  State<ManagerReportsPage> createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends State<ManagerReportsPage> {
  late final ReportService _reportService = di.sl<ReportService>();
  final _searchController = TextEditingController();
  String? _district;

  @override
  void initState() {
    super.initState();
    _district = widget.initialDistrict;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

    final title = isChichewa ? 'Ma Diagnosis' : 'All Diagnoses';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: isChichewa ? 'Sankhani District' : 'Filter by District',
            onPressed: () => _showDistrictSheet(context, isChichewa),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: isChichewa
                    ? 'Sakani mlimi, mbewu, kapena matenda...'
                    : 'Search farmer, crop, or disease...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          if (_district != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.location_on, size: 16),
                  label: Text(_district!),
                  onDeleted: () => setState(() => _district = null),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<DiagnosisReport>>(
              stream: _reportService.watchAllReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: isChichewa
                        ? 'Zalephera kutenga data. Yesaninso.'
                        : 'Failed to load data. Please try again.',
                    onRetry: () => setState(() {}),
                  );
                }

                final all = snapshot.data ?? const [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) {
                  return _EmptyState(
                    title: isChichewa ? 'Palibe zotsatira' : 'No diagnoses',
                    message: isChichewa
                        ? 'Yesani kusintha search kapena district.'
                        : 'Try adjusting search or district filter.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final report = filtered[index];
                      return _DiagnosisTile(
                        report: report,
                        isChichewa: isChichewa,
                        onOpen: () =>
                            _showDiagnosisDetail(context, report, isChichewa),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DiagnosisReport> _applyFilters(List<DiagnosisReport> all) {
    final q = _searchController.text.trim().toLowerCase();

    return all.where((r) {
      // District filter (optional)
      if (_district != null && (r.district ?? '').trim() != _district) {
        return false;
      }

      // Search filter
      if (q.isEmpty) return true;
      final haystack = [
        r.farmerName,
        r.farmerPhone,
        r.cropType,
        r.diagnosisName,
        r.district ?? '',
        r.placeName ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _showDistrictSheet(BuildContext context, bool isChichewa) {
    final controller = TextEditingController(text: _district ?? '');
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChichewa ? 'Sankhani District' : 'Filter by District',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: isChichewa ? 'Boma' : 'District',
                  hintText: isChichewa ? 'mwa: Blantyre' : 'e.g. Blantyre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _district = null);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(isChichewa ? 'Chotsani' : 'Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        setState(
                          () => _district = value.isEmpty ? null : value,
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(isChichewa ? 'Sankhani' : 'Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDiagnosisDetail(
    BuildContext context,
    DiagnosisReport report,
    bool isChichewa,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isChichewa ? 'Diagnosis ya Mlimi' : 'Farmer Diagnosis',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Farmer
              _sectionTitle(isChichewa ? 'Mlimi' : 'Farmer', Icons.person),
              const SizedBox(height: 8),
              _kv(isChichewa ? 'Dzina' : 'Name', report.farmerName),
              _kv(isChichewa ? 'Foni' : 'Phone', report.farmerPhone),

              const SizedBox(height: 16),

              // Location
              _sectionTitle(
                isChichewa ? 'Malo' : 'Location',
                Icons.location_on,
              ),
              const SizedBox(height: 8),
              _kv(
                isChichewa ? 'Boma' : 'District',
                (report.district ?? '').trim().isEmpty ? '-' : report.district!,
              ),
              _kv(
                isChichewa ? 'Malo Enieni' : 'Place',
                (report.placeName ?? '').trim().isEmpty
                    ? '-'
                    : report.placeName!,
              ),

              const SizedBox(height: 16),

              // Diagnosis
              _sectionTitle(isChichewa ? 'Vuto' : 'Issue', Icons.bug_report),
              const SizedBox(height: 8),
              _kv(isChichewa ? 'Mbewu' : 'Crop', report.cropType),
              _kv(isChichewa ? 'Matenda' : 'Disease', report.diagnosisName),
              _kv(
                isChichewa ? 'Kutsimikiza' : 'Confidence',
                '${(report.confidence * 100).toStringAsFixed(0)}%',
              ),

              if ((report.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(isChichewa ? 'Mawu' : 'Notes', Icons.notes),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(report.notes!),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isChichewa ? 'Tsekani' : 'Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _DiagnosisTile extends StatelessWidget {
  final DiagnosisReport report;
  final bool isChichewa;
  final VoidCallback onOpen;

  const _DiagnosisTile({
    required this.report,
    required this.isChichewa,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final highConfidence = report.confidence >= 0.7;
    final iconColor = highConfidence
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        onTap: onOpen,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.eco, color: iconColor),
        ),
        title: Text(
          report.farmerName,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${report.cropType} • ${report.diagnosisName}'),
            if ((report.district ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 2),
                  Text(report.district!, style: AppTextStyles.caption),
                ],
              ),
            ],
          ],
        ),
        trailing: Text(
          '${(report.confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: highConfidence ? AppTheme.healthyGreen : AppTheme.diseaseRed,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
