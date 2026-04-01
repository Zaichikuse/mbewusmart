import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DealerDashboardPage extends StatefulWidget {
  const DealerDashboardPage({super.key});

  @override
  State<DealerDashboardPage> createState() => _DealerDashboardPageState();
}

class _DealerDashboardPageState extends State<DealerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
    context.read<LocationBloc>().add(LocationGetCurrent());
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded 
        ? settingsState.languageCode == 'ny' 
        : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Dashboard ya Agro-Dealer' : 'Agro-Dealer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
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
              _buildStats(isChichewa),
              const SizedBox(height: 24),
              Text(
                isChichewa ? 'Zinthu zoyenera' : 'Products in Demand',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildProductsInDemand(isChichewa),
              const SizedBox(height: 24),
              Text(
                isChichewa ? 'Zopima zapafupi' : 'Nearby Diagnoses',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildRecentDiagnoses(isChichewa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isChichewa) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState.user?.fullName ?? 'Dealer';
    final locationState = context.watch<LocationBloc>().state;
    String location = '';
    if (locationState is LocationLoaded) {
      location = locationState.location.district ?? '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreenLight, AppTheme.primaryGreen],
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
              const Icon(Icons.store, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChichewa ? 'Welcomer' : 'Welcome',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          const SizedBox(height: 8),
          if (location.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            isChichewa 
                ? 'Onani zofunika za aMlimi m madera mwanu'
                : 'See what farmers in your area need',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isChichewa) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        int totalDiagnoses = 0;
        int pesticideNeeded = 0;
        int fertilizerNeeded = 0;

        if (state is DiagnosisHistoryLoaded) {
          totalDiagnoses = state.history.length;
          for (var d in state.history) {
            if (d.pesticideRemedy != null) pesticideNeeded++;
            if (d.type.name == 'deficiency') fertilizerNeeded++;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.eco,
                label: isChichewa ? 'Zopima' : 'Diagnoses',
                value: totalDiagnoses.toString(),
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.medication,
                label: isChichewa ? 'Mankhwala' : 'Pesticides',
                value: pesticideNeeded.toString(),
                color: AppTheme.diseaseRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.science,
                label: isChichewa ? 'Fertilizer' : 'Fertilizer',
                value: fertilizerNeeded.toString(),
                color: AppTheme.accentOrange,
              ),
            ),
          ],
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
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProductsInDemand(bool isChichewa) {
    final products = [
      {'name': 'Mancozeb', 'type': 'Fungicide', 'demand': 'High'},
      {'name': 'Urea', 'type': 'Fertilizer', 'demand': 'High'},
      {'name': 'Imidacloprid', 'type': 'Insecticide', 'demand': 'Medium'},
      {'name': 'Spinosad', 'type': 'Insecticide', 'demand': 'Medium'},
      {'name': 'CAN', 'type': 'Fertilizer', 'demand': 'Medium'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: products.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    p['type'] == 'Fungicide' 
                        ? Icons.healing 
                        : p['type'] == 'Insecticide' 
                            ? Icons.bug_report 
                            : Icons.science,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] as String, style: AppTextStyles.bodyMedium),
                      Text(p['type'] as String, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p['demand'] == 'High' 
                        ? AppTheme.diseaseRed.withValues(alpha: 0.1)
                        : AppTheme.warningAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p['demand'] as String,
                    style: TextStyle(
                      color: p['demand'] == 'High' 
                          ? AppTheme.diseaseRed 
                          : AppTheme.warningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentDiagnoses(bool isChichewa) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is DiagnosisLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DiagnosisHistoryLoaded) {
          if (state.history.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      isChichewa ? 'Palibe zopima' : 'No diagnoses yet',
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
            itemCount: state.history.take(5).length,
            itemBuilder: (context, index) {
              final diagnosis = state.history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(diagnosis.type.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(diagnosis.type.name),
                      color: _getTypeColor(diagnosis.type.name),
                    ),
                  ),
                  title: Text(diagnosis.diagnosisName),
                  subtitle: Text(diagnosis.cropType.displayName),
                  trailing: diagnosis.pesticideRemedy != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.diseaseRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pesticide',
                            style: TextStyle(
                              color: AppTheme.diseaseRed,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'disease':
        return AppTheme.diseaseRed;
      case 'pest':
        return AppTheme.pestOrange;
      case 'deficiency':
        return AppTheme.deficiencyYellow;
      case 'healthy':
        return AppTheme.healthyGreen;
      default:
        return AppTheme.textLight;
    }
  }

  IconData _getTypeIcon(String type) {
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
}
