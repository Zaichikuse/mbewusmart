import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

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

  late ManagerReportsFilter _filter;
  String? _district;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
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
    final isChichewa =
        settingsState is SettingsLoaded ? settingsState.languageCode == 'ny' : true;

    final title = isChichewa ? 'Ma Diagnosis ndi Ma Report' : 'Diagnoses & Reports';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterSheet(context, isChichewa),
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
                hintText: isChichewa ? 'Sakani...' : 'Search...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          if (_district != null || _filter != ManagerReportsFilter.allDiagnoses)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_district != null)
                    Chip(
                      label: Text(_district!),
                      onDeleted: () => setState(() => _district = null),
                    ),
                  if (_filter != ManagerReportsFilter.allDiagnoses)
                    Chip(
                      label: Text(_filterLabel(isChichewa)),
                      onDeleted: () =>
                          setState(() => _filter = ManagerReportsFilter.allDiagnoses),
                    ),
                ],
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
                    title: isChichewa ? 'Palibe zotsatira' : 'No results',
                    message: isChichewa
                        ? 'Yesani kusintha filter kapena search.'
                        : 'Try adjusting filters or search.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Firestore stream auto-updates; force rebuild for UX.
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final report = filtered[index];
                      return _ReportTile(
                        report: report,
                        isChichewa: isChichewa,
                        onOpen: () => _showReportDetail(context, report, isChichewa),
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
      if (_district != null && (r.district ?? '').trim() != _district) {
        return false;
      }
      if (_filter == ManagerReportsFilter.pendingOnly && r.status == 'reviewed') {
        return false;
      }
      if (_filter == ManagerReportsFilter.reviewedOnly && r.status != 'reviewed') {
        return false;
      }
      if (q.isEmpty) return true;

      final haystack = [
        r.farmerName,
        r.farmerPhone,
        r.cropType,
        r.diagnosisName,
        r.district ?? '',
        r.placeName ?? '',
        r.status,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  String _filterLabel(bool isChichewa) {
    switch (_filter) {
      case ManagerReportsFilter.allDiagnoses:
        return isChichewa ? 'Zonse' : 'All';
      case ManagerReportsFilter.pendingOnly:
        return isChichewa ? 'Zosabwerera' : 'Pending';
      case ManagerReportsFilter.reviewedOnly:
        return isChichewa ? 'Zachapa' : 'Reviewed';
    }
  }

  void _showFilterSheet(BuildContext context, bool isChichewa) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChichewa ? 'Sankhani Filter' : 'Filters',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ManagerReportsFilter>(
                value: _filter,
                decoration: InputDecoration(
                  labelText: isChichewa ? 'Status' : 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ManagerReportsFilter.allDiagnoses,
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: ManagerReportsFilter.pendingOnly,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: ManagerReportsFilter.reviewedOnly,
                    child: Text('Reviewed'),
                  ),
                ],
                onChanged: (v) => setState(() => _filter = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _district ?? '',
                decoration: InputDecoration(
                  labelText: isChichewa ? 'District (optional)' : 'District (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => _district = v.trim().isEmpty ? null : v.trim(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(isChichewa ? 'Tsekani' : 'Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDetail(
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
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.farmerName,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  Chip(
                    label: Text(report.status),
                    backgroundColor: report.status == 'reviewed'
                        ? AppTheme.healthyGreen.withValues(alpha: 0.12)
                        : AppTheme.warningAmber.withValues(alpha: 0.12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${report.cropType} • ${report.diagnosisName}'),
              const SizedBox(height: 8),
              Text(
                '${(report.confidence * 100).toStringAsFixed(0)}% ${isChichewa ? 'chikumbutso' : 'confidence'}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              _kv(isChichewa ? 'District' : 'District', report.district ?? '-'),
              _kv(isChichewa ? 'Place' : 'Place', report.placeName ?? '-'),
              _kv(isChichewa ? 'Phone' : 'Phone', report.farmerPhone),
              const SizedBox(height: 12),
              Text(
                isChichewa ? 'Notes' : 'Notes',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text((report.notes ?? '').trim().isEmpty ? '-' : report.notes!),
              const SizedBox(height: 16),
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(k, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final DiagnosisReport report;
  final bool isChichewa;
  final VoidCallback onOpen;

  const _ReportTile({
    required this.report,
    required this.isChichewa,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = report.status == 'reviewed'
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onOpen,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.eco, color: statusColor),
        ),
        title: Text(report.farmerName),
        subtitle: Text(
          '${report.cropType} • ${report.diagnosisName}'
          '${(report.district ?? '').trim().isEmpty ? '' : ' • ${report.district}'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(report.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: report.confidence >= 0.7
                    ? AppTheme.healthyGreen
                    : AppTheme.diseaseRed,
              ),
            ),
            const SizedBox(height: 4),
            Text(report.status, style: AppTextStyles.caption),
          ],
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
              style: AppTextStyles.headingSmall.copyWith(color: AppTheme.textMuted),
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

