import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/pressable.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';
import 'manager_reports_page.dart';
import 'manager_alerts_page.dart';
import 'manager_analytics_page.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  late final ReportService _reportService = di.sl<ReportService>();

  @override
  void initState() {
    super.initState();
    context.read<AlertsBloc>().add(AlertsLoadRequested());
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChichewa ? 'Dashboard ya Manager' : 'Agriculture Manager Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AlertsBloc>().add(AlertsLoadRequested());
              context.read<DiagnosisBloc>().add(
                const DiagnosisHistoryRequested(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AlertsBloc>().add(AlertsLoadRequested());
          context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(isChichewa),
              const SizedBox(height: 16),
              _buildAnalyticsButton(isChichewa),
              const SizedBox(height: 20),
              _buildOverviewStats(isChichewa),
              const SizedBox(height: 24),
              Text(
                isChichewa ? 'Ma District' : 'District Overview',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildDistrictStats(isChichewa),
              const SizedBox(height: 24),
              Text(
                isChichewa ? 'Ma Alert a pafupi' : 'Recent Alerts',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildRecentAlerts(isChichewa),
              const SizedBox(height: 24),
              Text(
                isChichewa ? 'Ma Report' : 'Reports',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildReportsList(isChichewa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsButton(bool isChichewa) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManagerAnalyticsPage()),
          );
        },
        icon: const Icon(Icons.insights),
        label: Text(
          isChichewa
              ? 'Onani Kafukufuku Yense'
              : 'View Full Analytics Dashboard',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isChichewa) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState.user?.fullName ?? 'Manager';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChichewa ? 'Mwalandiridwa' : 'Welcome',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isChichewa
                ? 'Onani mbiri ya alimi onse mu boma lanu'
                : 'Monitor all farmers and extension officers in your district',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(bool isChichewa) {
    return BlocBuilder<AlertsBloc, AlertsState>(
      builder: (context, alertsState) {
        return BlocBuilder<DiagnosisBloc, DiagnosisState>(
          builder: (context, diagnosisState) {
            int totalDiagnoses = 0;
            int totalAlerts = 0;
            int pendingAlerts = 0;
            int resolvedAlerts = 0;

            if (diagnosisState is DiagnosisHistoryLoaded) {
              totalDiagnoses = diagnosisState.history.length;
            }
            if (alertsState is AlertsLoaded) {
              totalAlerts = alertsState.alerts.length;
              resolvedAlerts = alertsState.alerts
                  .where(
                    (a) =>
                        a.officerResponse != null &&
                        a.officerResponse!.trim().isNotEmpty,
                  )
                  .length;
              pendingAlerts = totalAlerts - resolvedAlerts;
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.analytics,
                        label: isChichewa ? 'Zopima Zonse' : 'Total Diagnoses',
                        value: totalDiagnoses.toString(),
                        color: AppTheme.primaryGreen,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerReportsPage(
                                initialFilter:
                                    ManagerReportsFilter.allDiagnoses,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.warning_amber,
                        label: isChichewa ? 'Ma Alert' : 'Total Alerts',
                        value: totalAlerts.toString(),
                        color: AppTheme.warningAmber,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerAlertsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.pending_actions,
                        label: isChichewa ? 'Zodikira' : 'Pending',
                        value: pendingAlerts.toString(),
                        color: AppTheme.diseaseRed,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerAlertsPage(
                                initialFilter: ManagerAlertsFilter.pendingOnly,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: isChichewa ? 'Yathandizidwa' : 'Resolved',
                        value: resolvedAlerts.toString(),
                        color: AppTheme.healthyGreen,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerAlertsPage(
                                initialFilter: ManagerAlertsFilter.reviewedOnly,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headingMedium),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Pressable(onTap: onTap, child: card);
  }

  // ============================================
  // REAL DISTRICT OVERVIEW — pulls live from Firestore
  // ============================================
  Widget _buildDistrictStats(bool isChichewa) {
    return StreamBuilder<List<DiagnosisReport>>(
      stream: _reportService.watchAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final reports = snapshot.data ?? const [];

        if (reports.isEmpty) {
          return _emptyDistrictCard(
            isChichewa
                ? 'Palibe data ya maboma panopa.'
                : 'No district data yet.',
          );
        }

        // Group reports by district, falling back to placeName for legacy docs
        final districtCounts = <String, int>{};
        for (final r in reports) {
          final district = (r.district ?? r.placeName ?? '').trim();
          if (district.isEmpty || district.toLowerCase() == 'unknown') continue;
          districtCounts[district] = (districtCounts[district] ?? 0) + 1;
        }

        if (districtCounts.isEmpty) {
          return _emptyDistrictCard(
            isChichewa
                ? 'Palibe data ya maboma yokhala ndi malo.'
                : 'No district data with locations yet.',
          );
        }

        // Sort districts: highest case count first
        final sortedDistricts = districtCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final maxCount = sortedDistricts.first.value;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        isChichewa ? 'Boma' : 'District',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        isChichewa ? 'Zopima' : 'Cases',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(height: 1),
              // District rows
              ...sortedDistricts.map((entry) {
                final district = entry.key;
                final count = entry.value;
                final percentage = count / maxCount;
                final severityColor = count >= 5
                    ? AppTheme.diseaseRed
                    : count >= 3
                    ? AppTheme.warningAmber
                    : AppTheme.healthyGreen;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                district,
                                style: AppTextStyles.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                severityColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          count.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyDistrictCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(bool isChichewa) {
    return BlocBuilder<AlertsBloc, AlertsState>(
      builder: (context, state) {
        if (state is AlertsLoaded) {
          if (state.alerts.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: AppTheme.healthyGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isChichewa ? 'Palibe alert' : 'No alerts',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.alerts.take(5).length,
            itemBuilder: (context, index) {
              final alert = state.alerts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningAmber,
                    ),
                  ),
                  title: Text(alert.farmerName),
                  subtitle: Text('${alert.cropName} - ${alert.location}'),
                  trailing: Text(
                    '${(alert.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: alert.confidence >= 0.7
                          ? AppTheme.healthyGreen
                          : AppTheme.diseaseRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReportsList(bool isChichewa) {
    return StreamBuilder<List<DiagnosisReport>>(
      stream: _reportService.watchAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppTheme.healthyGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isChichewa ? 'Palibe report' : 'No reports',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  Widget _buildReportCard(DiagnosisReport report) {
    final statusColor = report.status == 'reviewed'
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.eco, color: statusColor),
        ),
        title: Text(report.farmerName),
        subtitle: Text('${report.cropType} - ${report.diagnosisName}'),
        trailing: Text(
          '${(report.confidence * 100).toStringAsFixed(0)}% ',
          style: TextStyle(
            color: report.confidence >= 0.7
                ? AppTheme.healthyGreen
                : AppTheme.diseaseRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
