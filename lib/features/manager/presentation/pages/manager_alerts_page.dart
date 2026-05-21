import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

enum ManagerAlertsFilter { all, pendingOnly, reviewedOnly }

class ManagerAlertsPage extends StatefulWidget {
  final ManagerAlertsFilter initialFilter;

  const ManagerAlertsPage({
    super.key,
    this.initialFilter = ManagerAlertsFilter.all,
  });

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
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

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
                hintText: isChichewa ? 'Fufuzani...' : 'Search...',
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
                    title: isChichewa ? 'Zakanika' : 'Failed',
                    message: state.message,
                    action: ElevatedButton(
                      onPressed: () =>
                          context.read<AlertsBloc>().add(AlertsLoadRequested()),
                      child: Text(isChichewa ? 'Yesaninso' : 'Retry'),
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
                        return _AlertTile(alert: alert, isChichewa: isChichewa);
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

  // Determine if an alert is resolved (officerResponse is the source of truth)
  bool _isResolved(Alert alert) {
    return alert.officerResponse != null &&
        alert.officerResponse!.trim().isNotEmpty;
  }

  List<Alert> _applyFilters(List<Alert> all) {
    final q = _searchController.text.trim().toLowerCase();

    return all.where((a) {
      final resolved = _isResolved(a);
      if (_filter == ManagerAlertsFilter.pendingOnly && resolved) {
        return false;
      }
      if (_filter == ManagerAlertsFilter.reviewedOnly && !resolved) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack = [
        a.farmerName,
        a.farmerPhone,
        a.location,
        a.district,
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
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(isChichewa ? 'Zonse' : 'All'),
                        selected: _filter == ManagerAlertsFilter.all,
                        onSelected: (_) {
                          setState(() => _filter = ManagerAlertsFilter.all);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: Text(isChichewa ? 'Sizinakonzedwe' : 'Pending'),
                        selected: _filter == ManagerAlertsFilter.pendingOnly,
                        onSelected: (_) {
                          setState(
                            () => _filter = ManagerAlertsFilter.pendingOnly,
                          );
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: Text(isChichewa ? 'Zakonzedwa' : 'Resolved'),
                        selected: _filter == ManagerAlertsFilter.reviewedOnly,
                        onSelected: (_) {
                          setState(
                            () => _filter = ManagerAlertsFilter.reviewedOnly,
                          );
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(isChichewa ? 'Tamaliza' : 'Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;
  final bool isChichewa;

  const _AlertTile({required this.alert, required this.isChichewa});

  bool get _isResolved =>
      alert.officerResponse != null && alert.officerResponse!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.confidence >= 0.7
        ? AppTheme.diseaseRed
        : AppTheme.warningAmber;

    final statusColor = _isResolved
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;
    final statusText = _isResolved
        ? (isChichewa ? 'Yathandizidwa' : 'Resolved')
        : (isChichewa ? 'Yodikira' : 'Pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber, color: severityColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.farmerName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${alert.cropName} • ${alert.diagnosisName}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(alert.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: severityColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.district.isNotEmpty
                          ? alert.district
                          : (alert.location.isNotEmpty
                                ? alert.location
                                : (isChichewa ? 'Sizidziwika' : 'Unknown')),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (alert.note.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '"${alert.note}"',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppTheme.diseaseRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isChichewa ? 'Alert ya Mlimi' : 'Farmer Alert',
                          style: AppTextStyles.headingSmall,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const Divider(height: 24),

                  // Farmer Info Section
                  _buildSectionTitle(
                    isChichewa ? 'Mlimi' : 'Farmer',
                    Icons.person,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.person_outline,
                    isChichewa ? 'Dzina' : 'Name',
                    alert.farmerName,
                  ),
                  _buildDetailRow(
                    Icons.phone,
                    isChichewa ? 'Foni' : 'Phone',
                    alert.farmerPhone,
                  ),

                  const SizedBox(height: 16),

                  // Location Section
                  _buildSectionTitle(
                    isChichewa ? 'Malo' : 'Location',
                    Icons.location_on,
                  ),
                  const SizedBox(height: 8),
                  if (alert.district.isNotEmpty)
                    _buildDetailRow(
                      Icons.map,
                      isChichewa ? 'Boma' : 'District',
                      alert.district,
                    ),
                  if (alert.location.isNotEmpty)
                    _buildDetailRow(
                      Icons.place,
                      isChichewa ? 'Malo Enieni' : 'Place',
                      alert.location,
                    ),
                  if (alert.location.isEmpty && alert.district.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isChichewa ? 'Sizidziwika' : 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Diagnosis Section
                  _buildSectionTitle(
                    isChichewa ? 'Vuto' : 'Issue',
                    Icons.bug_report,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.local_florist,
                    isChichewa ? 'Mbewu' : 'Crop',
                    alert.cropName,
                  ),
                  _buildDetailRow(
                    Icons.coronavirus,
                    isChichewa ? 'Matenda' : 'Disease',
                    alert.diagnosisName,
                  ),
                  _buildDetailRow(
                    Icons.percent,
                    isChichewa ? 'Kutsimikiza' : 'Confidence',
                    '${(alert.confidence * 100).toStringAsFixed(0)}%',
                  ),
                  _buildDetailRow(
                    Icons.access_time,
                    isChichewa ? 'Nthawi' : 'Time',
                    timeAgoFromTimestamp(alert.timestamp),
                  ),

                  const SizedBox(height: 16),

                  // Farmer's Notes Section
                  _buildSectionTitle(
                    isChichewa ? 'Mawu a Mlimi' : "Farmer's Notes",
                    Icons.notes,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      alert.note.trim().isEmpty
                          ? (isChichewa ? 'Palibe mawu' : 'No notes provided')
                          : alert.note,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),

                  // Manager Response Section (if resolved)
                  if (_isResolved) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle(
                      isChichewa ? 'Yankho la Manager' : 'Manager Response',
                      Icons.check_circle,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.healthyGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.healthyGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        alert.officerResponse!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    if (alert.respondedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${isChichewa ? "Yathandizidwa" : "Resolved on"} ${timeAgoFromTimestamp(alert.respondedAt!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callFarmer(alert.farmerPhone),
                          icon: const Icon(Icons.phone),
                          label: Text(isChichewa ? 'Lowa Foni' : 'Call Farmer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!_isResolved)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _markAsResolved(context, ctx, isChichewa),
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          isChichewa
                              ? 'Tsimikizani Yathandizidwa'
                              : 'Mark as Resolved',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.healthyGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.healthyGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.healthyGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isChichewa
                                ? 'Alert Yathandizidwa'
                                : 'Alert Resolved',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.healthyGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = _isResolved
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;
    final statusText = _isResolved
        ? (isChichewa ? 'Yathandizidwa' : 'Resolved')
        : (isChichewa ? 'Yodikira' : 'Pending');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
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

  Future<void> _callFarmer(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty || phoneNumber == 'Unknown') return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _markAsResolved(
    BuildContext context,
    BuildContext sheetContext,
    bool isChichewa,
  ) {
    final defaultResponse = isChichewa
        ? 'Yathandizidwa ndi Manager.'
        : 'Reviewed and resolved by Manager.';

    // Use existing AlertResponseAdded event - it sets officerResponse
    // which is what determines "resolved" status
    context.read<AlertsBloc>().add(
      AlertResponseAdded(alert.id, defaultResponse),
    );

    Navigator.of(sheetContext).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isChichewa
              ? 'Alert yatsimikizidwa kuti yathandizidwa'
              : 'Alert marked as resolved',
        ),
        backgroundColor: AppTheme.healthyGreen,
      ),
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
              style: AppTextStyles.headingSmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
