import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../location/presentation/pages/nearby_help_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load diagnosis history
    try {
      context.read<DiagnosisBloc>().add(DiagnosisHistoryRequested());
    } catch (e) {
      // Ignore if bloc is not available
    }
  }

  String _getLanguageCode() {
    try {
      final settingsState = context.read<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        return settingsState.languageCode;
      }
    } catch (e) {
      // Use default
    }
    return 'ny';
  }

  @override
  Widget build(BuildContext context) {
    final isChichewa = _getLanguageCode() == 'ny';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MbewuSmart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(context, isChichewa),
              const SizedBox(height: 24),
              _buildQuickActions(context, isChichewa),
              const SizedBox(height: 24),
              _buildRecentDiagnoses(context, isChichewa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, bool isChichewa) {
    String userName = isChichewa ? 'Mwandi' : 'Farmer';

    try {
      final authState = context.watch<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        userName = authState.user!.fullName.split(' ').first;
      }
    } catch (e) {
      // Use default
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppUtils.getGreeting(context, isChichewa),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isChichewa
                ? 'Tiyeni tipimshe zizolongo zanu'
                : "Let's check your crops today",
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isChichewa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Zochita Zapakati' : 'Quick Actions',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                label: isChichewa ? 'Pima' : 'Scan',
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ScanPage()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                label: isChichewa ? 'Mbiri' : 'History',
                color: AppTheme.accentOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
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
              child: _buildActionCard(
                icon: Icons.location_on,
                label: isChichewa ? 'Thandizo Langa' : 'Nearby Help',
                color: AppTheme.warningAmber,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NearbyHelpPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                label: isChichewa ? 'Mrapato' : 'Reports',
                color: AppTheme.primaryGreenLight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDiagnoses(BuildContext context, bool isChichewa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Zopima Zatsopano' : 'Recent Diagnoses',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        _buildDiagnosisList(context, isChichewa),
      ],
    );
  }

  Widget _buildDiagnosisList(BuildContext context, bool isChichewa) {
    try {
      return BlocBuilder<DiagnosisBloc, DiagnosisState>(
        builder: (context, state) {
          if (state is DiagnosisLoading) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingIndicator(),
            );
          }

          if (state is DiagnosisHistoryLoaded) {
            if (state.history.isEmpty) {
              return _buildEmptyState(isChichewa);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.history.take(3).length,
              itemBuilder: (context, index) {
                final result = state.history[index];
                return _buildHistoryCard(result, isChichewa);
              },
            );
          }

          if (state is DiagnosisError) {
            return _buildErrorState(state.message, isChichewa);
          }

          return _buildEmptyState(isChichewa);
        },
      );
    } catch (e) {
      return _buildEmptyState(isChichewa);
    }
  }

  Widget _buildEmptyState(bool isChichewa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: EmptyState(
        title: isChichewa ? 'Palibe zopima mpaka pano' : 'No diagnoses yet',
        message: isChichewa
            ? 'Zopima zanu zidzasungidwa apa'
            : 'Your diagnoses will appear here',
        icon: Icons.eco_outlined,
      ),
    );
  }

  Widget _buildErrorState(String message, bool isChichewa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic result, bool isChichewa) {
    final typeName = _safeEnumName(result.type);
    final severityName = _safeEnumName(result.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSeverityColor(result.severity).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDiagnosisIcon(typeName),
            color: _getSeverityColor(result.severity),
          ),
        ),
        title: Text(result.diagnosisName ?? 'Unknown'),
        subtitle: Text(
          '${typeName.isEmpty ? 'Unknown' : typeName} - ${severityName.isEmpty ? 'Unknown' : severityName}',
          style: TextStyle(color: _getSeverityColor(result.severity)),
        ),
        trailing: Text(
          _formatDate(result.timestamp),
          style: AppTextStyles.caption,
        ),
      ),
    );
  }

  String _safeEnumName(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    final separator = text.lastIndexOf('.');
    if (separator == -1 || separator == text.length - 1) {
      return text;
    }
    return text.substring(separator + 1);
  }

  Color _getSeverityColor(dynamic severity) {
    if (severity == null) return AppTheme.textMuted;
    switch (severity.toString()) {
      case 'Severity.low':
        return AppTheme.healthyGreen;
      case 'Severity.medium':
        return AppTheme.warningAmber;
      case 'Severity.high':
        return AppTheme.diseaseRed;
      default:
        return AppTheme.textLight;
    }
  }

  IconData _getDiagnosisIcon(String type) {
    switch (type.toLowerCase()) {
      case 'disease':
        return Icons.coronavirus;
      case 'pest':
        return Icons.bug_report;
      case 'deficiency':
        return Icons.science;
      case 'healthy':
        return Icons.check_circle;
      default:
        return Icons.eco;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
