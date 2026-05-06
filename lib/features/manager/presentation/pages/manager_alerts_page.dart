import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

enum ManagerAlertsFilter { all, pendingOnly, reviewedOnly }

class ManagerAlertsPage extends StatefulWidget {
  final ManagerAlertsFilter initialFilter;

  const ManagerAlertsPage({super.key, this.initialFilter = ManagerAlertsFilter.all});

  @override
  State<ManagerAlertsPage> createState() => _ManagerAlertsPageState();
}

class _ManagerAlertsPageState extends State<ManagerAlertsPage> {
  final _searchController = TextEditingController();
  late ManagerAlertsFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController.addListener(() => setState(() {}));
    context.read<AlertsBloc>().add(AlertsLoadRequested());
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Ma Alert' : 'Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterDialog(context, isChichewa),
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
          Expanded(
            child: BlocBuilder<AlertsBloc, AlertsState>(
              builder: (context, state) {
                if (state is AlertsLoading || state is AlertsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AlertsError) {
                  return _CenteredMessage(
                    icon: Icons.error_outline,
                    title: isChichewa ? 'Zalephera' : 'Failed',
                    message: state.message,
                    action: ElevatedButton(
                      onPressed: () =>
                          context.read<AlertsBloc>().add(AlertsLoadRequested()),
                      child: Text(isChichewa ? 'Jarani' : 'Retry'),
                    ),
                  );
                }
                if (state is AlertsLoaded) {
                  final alerts = _applyFilters(state.alerts);
                  if (alerts.isEmpty) {
                    return _CenteredMessage(
                      icon: Icons.check_circle,
                      iconColor: AppTheme.healthyGreen,
                      title: isChichewa ? 'Palibe alert' : 'No alerts',
                      message: isChichewa
                          ? 'Palibe ma alert okwanira pa filter iyi.'
                          : 'No alerts match this filter.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<AlertsBloc>().add(AlertsLoadRequested());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _AlertTile(
                          alert: alert,
                          isChichewa: isChichewa,
                          onMarkReviewed: alert.isRead
                              ? null
                              : () => context
                                  .read<AlertsBloc>()
                                  .add(AlertMarkAsRead(alert.id)),
                          onAddResponse: () =>
                              _showResponseDialog(context, alert, isChichewa),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Alert> _applyFilters(List<Alert> all) {
    final q = _searchController.text.trim().toLowerCase();

    return all.where((a) {
      if (_filter == ManagerAlertsFilter.pendingOnly && a.officerResponse != null) {
        return false;
      }
      if (_filter == ManagerAlertsFilter.reviewedOnly && a.officerResponse == null) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack = [
        a.farmerName,
        a.farmerPhone,
        a.location,
        a.cropName,
        a.diagnosisName,
        a.note,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _showFilterDialog(BuildContext context, bool isChichewa) {
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
              RadioListTile<ManagerAlertsFilter>(
                value: ManagerAlertsFilter.all,
                groupValue: _filter,
                onChanged: (v) => setState(() => _filter = v!),
                title: Text(isChichewa ? 'Zonse' : 'All'),
              ),
              RadioListTile<ManagerAlertsFilter>(
                value: ManagerAlertsFilter.pendingOnly,
                groupValue: _filter,
                onChanged: (v) => setState(() => _filter = v!),
                title: Text(isChichewa ? 'Zosabwerera' : 'Pending'),
              ),
              RadioListTile<ManagerAlertsFilter>(
                value: ManagerAlertsFilter.reviewedOnly,
                groupValue: _filter,
                onChanged: (v) => setState(() => _filter = v!),
                title: Text(isChichewa ? 'Zachapa' : 'Resolved'),
              ),
              const SizedBox(height: 8),
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

  Future<void> _showResponseDialog(
    BuildContext context,
    Alert alert,
    bool isChichewa,
  ) async {
    final controller = TextEditingController(text: alert.officerResponse ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChichewa ? 'Yankho la Manager' : 'Manager Response'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: isChichewa ? 'Lembani yankho...' : 'Write a response...',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(isChichewa ? 'Iai' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(isChichewa ? 'Sunga' : 'Save'),
            ),
          ],
        );
      },
    );
    if (result != null && result.trim().isNotEmpty) {
      context.read<AlertsBloc>().add(AlertResponseAdded(alert.id, result.trim()));
    }
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;
  final bool isChichewa;
  final VoidCallback? onMarkReviewed;
  final VoidCallback onAddResponse;

  const _AlertTile({
    required this.alert,
    required this.isChichewa,
    required this.onMarkReviewed,
    required this.onAddResponse,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.confidence >= 0.7
        ? AppTheme.diseaseRed
        : AppTheme.warningAmber;

    final statusText = alert.officerResponse == null
        ? (isChichewa ? 'Pending' : 'Pending')
        : (isChichewa ? 'Resolved' : 'Resolved');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber, color: severityColor),
          ),
          title: Text(alert.farmerName),
          subtitle: Text('${alert.cropName} • ${alert.diagnosisName}\n${alert.location}'),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(alert.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: severityColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(statusText, style: AppTextStyles.caption),
            ],
          ),
          onTap: () => _showDetail(context),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.farmerName, style: AppTextStyles.headingSmall),
              const SizedBox(height: 6),
              Text('${alert.cropName} • ${alert.diagnosisName}'),
              const SizedBox(height: 6),
              Text(alert.location),
              const SizedBox(height: 12),
              Text(
                isChichewa ? 'Note' : 'Note',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(alert.note.trim().isEmpty ? '-' : alert.note),
              const SizedBox(height: 12),
              if (alert.officerResponse != null) ...[
                Text(
                  isChichewa ? 'Yankho' : 'Response',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(alert.officerResponse!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkReviewed,
                      child: Text(
                        alert.isRead
                            ? (isChichewa ? 'Reviewed' : 'Reviewed')
                            : (isChichewa ? 'Mark reviewed' : 'Mark reviewed'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onAddResponse();
                      },
                      child: Text(isChichewa ? 'Yankho' : 'Respond'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final Widget? action;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor ?? AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

