import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

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
                      isChichewa ? 'Welcomer' : 'Welcome',
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
                ? 'Onani mbiri ya aMlimi onse m district'
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
              pendingAlerts = alertsState.unreadCount;
              resolvedAlerts = alertsState.alerts
                  .where((a) => a.officerResponse != null)
                  .length;
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.warning_amber,
                        label: isChichewa ? 'Ma Alert' : 'Total Alerts',
                        value: totalAlerts.toString(),
                        color: AppTheme.warningAmber,
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
                        label: isChichewa ? 'Zosabwerera' : 'Pending',
                        value: pendingAlerts.toString(),
                        color: AppTheme.diseaseRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: isChichewa ? 'Zachapa' : 'Resolved',
                        value: resolvedAlerts.toString(),
                        color: AppTheme.healthyGreen,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
    );
  }

  Widget _buildDistrictStats(bool isChichewa) {
    final districts = [
      {'name': 'Blantyre', 'cases': 45, 'officers': 2},
      {'name': 'Lilongwe', 'cases': 38, 'officers': 2},
      {'name': 'Mzuzu', 'cases': 22, 'officers': 1},
      {'name': 'Zomba', 'cases': 18, 'officers': 1},
      {'name': 'Mulanje', 'cases': 15, 'officers': 1},
      {'name': 'Kasungu', 'cases': 12, 'officers': 1},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: districts.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    d['name'] as String,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${d['officers']}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.eco, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text('${d['cases']}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
