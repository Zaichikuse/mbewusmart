import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

class OfficerDashboardPage extends StatefulWidget {
  const OfficerDashboardPage({super.key});

  @override
  State<OfficerDashboardPage> createState() => _OfficerDashboardPageState();
}

class _OfficerDashboardPageState extends State<OfficerDashboardPage> {
  late final ReportService _reportService = di.sl<ReportService>();

  @override
  void initState() {
    super.initState();
    context.read<AlertsBloc>().add(AlertsLoadRequested());
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
          isChichewa ? 'Dashboard ya Afesa' : 'Extension Officer Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AlertsBloc>().add(AlertsLoadRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AlertsBloc>().add(AlertsLoadRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(isChichewa),
                  const SizedBox(height: 20),
                  _buildStatsCards(state, isChichewa),
                  const SizedBox(height: 24),
                  Text(
                    isChichewa ? 'Ma Alert' : 'Low Confidence Cases',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildAlertsList(state, isChichewa),
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
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(bool isChichewa) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState.user?.fullName ?? 'Officer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentOrange, AppTheme.primaryGreenLight],
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
              const Icon(Icons.person, color: Colors.white, size: 32),
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
                ? 'Pitani ku Field kuti mulandre ndi aMlimi'
                : 'Visit fields to assist farmers with their crop issues',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AlertsState state, bool isChichewa) {
    int totalAlerts = 0;
    int unreadAlerts = 0;
    int respondedAlerts = 0;

    if (state is AlertsLoaded) {
      totalAlerts = state.alerts.length;
      unreadAlerts = state.unreadCount;
      respondedAlerts = state.alerts
          .where((a) => a.officerResponse != null)
          .length;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning_amber,
            label: isChichewa ? 'Zoti Review' : 'Total Cases',
            value: totalAlerts.toString(),
            color: AppTheme.accentOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.mark_email_unread,
            label: isChichewa ? 'Zosabwera' : 'Unread',
            value: unreadAlerts.toString(),
            color: AppTheme.diseaseRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: isChichewa ? 'Zachapa' : 'Responded',
            value: respondedAlerts.toString(),
            color: AppTheme.healthyGreen,
          ),
        ),
      ],
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

  Widget _buildAlertsList(AlertsState state, bool isChichewa) {
    if (state is AlertsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AlertsLoaded) {
      if (state.alerts.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: AppTheme.healthyGreen),
              const SizedBox(height: 12),
              Text(
                isChichewa ? 'Palibe alert' : 'No alerts yet',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.alerts.length,
        itemBuilder: (context, index) {
          final alert = state.alerts[index];
          return _buildAlertCard(alert, isChichewa);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAlertCard(dynamic alert, bool isChichewa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAlertDetail(alert, isChichewa),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alert.isRead
                          ? Colors.grey.shade100
                          : AppTheme.warningAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: alert.isRead ? Colors.grey : AppTheme.warningAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.farmerName,
                          style: AppTextStyles.headingSmall,
                        ),
                        Text(alert.cropName, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(alert.confidence),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(alert.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(alert.location, style: AppTextStyles.caption),
                  const Spacer(),
                  Text(
                    _formatDate(alert.timestamp),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              if (alert.officerResponse != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.healthyGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: AppTheme.healthyGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isChichewa ? 'Wayankha kale' : 'Responded',
                          style: TextStyle(color: AppTheme.healthyGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetail(dynamic alert, bool isChichewa) {
    final responseController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isChichewa ? 'Zambiri za Alert' : 'Alert Details',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow(
                    isChichewa ? 'Mlimi' : 'Farmer',
                    alert.farmerName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Foni' : 'Phone',
                    alert.farmerPhone,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Location' : 'Location',
                    alert.location,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Mbewo' : 'Crop',
                    alert.cropName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Matenda' : 'Diagnosis',
                    alert.diagnosisName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Confidence' : 'Confidence',
                    '${(alert.confidence * 100).toStringAsFixed(0)}%',
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Tsiku' : 'Date',
                    _formatDate(alert.timestamp),
                  ),

                  const SizedBox(height: 20),

                  if (alert.officerResponse != null) ...[
                    Text(
                      isChichewa ? 'Yankho Lanu' : 'Your Response',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.healthyGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(alert.officerResponse),
                    ),
                  ] else ...[
                    Text(
                      isChichewa
                          ? 'Lankhulani Yankho'
                          : 'Add Professional Opinion',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: isChichewa
                            ? 'Lankhulani zoti mukuganiza...'
                            : 'Write your professional opinion...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (responseController.text.isNotEmpty) {
                            this.context.read<AlertsBloc>().add(
                              AlertResponseAdded(
                                alert.id,
                                responseController.text,
                              ),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isChichewa
                                      ? 'Yankho salidwa!'
                                      : 'Response saved!',
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          isChichewa ? 'Sunga Yankho' : 'Submit Response',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportsList(bool isChichewa) {
    final officerId = context.read<AuthBloc>().state.user?.id;
    if (officerId == null || officerId.trim().isEmpty) {
      return _buildEmptyReports(isChichewa);
    }

    return StreamBuilder<List<DiagnosisReport>>(
      stream: _reportService.watchReportsForOfficer(officerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return _buildEmptyReports(isChichewa);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, isChichewa);
          },
        );
      },
    );
  }

  Widget _buildEmptyReports(bool isChichewa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 48,
            color: AppTheme.healthyGreen,
          ),
          const SizedBox(height: 12),
          Text(
            isChichewa ? 'Palibe report pano' : 'No reports yet',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(DiagnosisReport report, bool isChichewa) {
    final statusColor = report.status == 'reviewed'
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReportDetail(report, isChichewa),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.eco, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.farmerName,
                          style: AppTextStyles.headingSmall,
                        ),
                        Text(
                          report.diagnosisName,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(report.confidence),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(report.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.placeName ?? report.district ?? 'Unknown',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(report.timestamp),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              if (report.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.healthyGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: AppTheme.healthyGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isChichewa ? 'Wayankha kale' : 'Responded',
                          style: TextStyle(color: AppTheme.healthyGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetail(DiagnosisReport report, bool isChichewa) {
    final responseController = TextEditingController(text: report.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isChichewa ? 'Zambiri za Report' : 'Report Details',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    isChichewa ? 'Mlimi' : 'Farmer',
                    report.farmerName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Foni' : 'Phone',
                    report.farmerPhone,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Location' : 'Location',
                    report.placeName ?? report.district ?? 'Unknown',
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Mbewo' : 'Crop',
                    report.cropType,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Matenda' : 'Diagnosis',
                    report.diagnosisName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Confidence' : 'Confidence',
                    '${(report.confidence * 100).toStringAsFixed(0)}%',
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Tsiku' : 'Date',
                    _formatDate(report.timestamp),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isChichewa ? 'Zolemba' : 'Notes',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: responseController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isChichewa
                          ? 'Lembani zomwe mwapeza...'
                          : 'Add your professional notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final notes = responseController.text.trim();
                        await _reportService.updateReportNotes(
                          reportId: report.id,
                          notes: notes,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isChichewa
                                    ? 'Zolemba zasungidwa!'
                                    : 'Notes saved!',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(isChichewa ? 'Sunga Zolemba' : 'Save Notes'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return AppTheme.healthyGreen;
    if (confidence >= 0.5) return AppTheme.warningAmber;
    return AppTheme.diseaseRed;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
