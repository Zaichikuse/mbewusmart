import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../../shared/routes/app_routes.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../location/presentation/pages/nearby_help_page.dart';
import '../../../scan/presentation/widgets/crop_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<LocationBloc>().add(LocationGetCurrent());
        final userId = context.read<AuthBloc>().state.user?.id;
        context.read<DiagnosisBloc>().add(
          DiagnosisHistoryRequested(userId: userId),
        );
      } catch (e) {
        // Ignore if bloc is not available
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = LocalizationHelper.getAppLocalizations(context);
    final isChichewa = LocalizationHelper.isChichewa(context);

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
      body: BlocListener<DiagnosisBloc, DiagnosisState>(
        listenWhen: (previous, current) => current is DiagnosisSuccess,
        listener: (context, state) {
          if (state is DiagnosisSuccess) {
            final userId = context.read<AuthBloc>().state.user?.id;
            context.read<DiagnosisBloc>().add(
              DiagnosisHistoryRequested(userId: userId),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingCard(context, appLoc, isChichewa),
                const SizedBox(height: 24),
                _buildQuickActions(context, appLoc, isChichewa),
                const SizedBox(height: 24),
                _buildCropCards(context, isChichewa),
                const SizedBox(height: 24),
                _buildRecentDiagnoses(context, appLoc, isChichewa),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(
    BuildContext context,
    AppLocalizations appLoc,
    bool isChichewa,
  ) {
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
            AppUtils.getGreeting(context),
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
            appLoc.welcomeMessage,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations appLoc,
    bool isChichewa,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Zochita Zachangu' : 'Quick Actions',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                label: appLoc.scan,
                color: AppTheme.primaryGreen,
                pulse: true,
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
                label: appLoc.history,
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
                label: appLoc.nearbyHelp,
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
                label: appLoc.reports,
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

  Widget _buildCropCards(BuildContext context, bool isChichewa) {
    return CropSelector(
      title: isChichewa ? 'Sankhani Mbewu' : 'Browse by Crop',
      selectedCrop: CropType.maize,
      onCropSelected: (crop) {
        context.go(AppRoutes.diseaseWatchPath(crop.name));
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    final card = Pressable(
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

    if (!pulse) {
      return card;
    }

    return card
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.03,
          duration: 1400.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildRecentDiagnoses(
    BuildContext context,
    AppLocalizations appLoc,
    bool isChichewa,
  ) {
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
              itemCount: state.history.take(5).length,
              itemBuilder: (context, index) {
                final result = state.history.take(5).toList()[index];
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
            ? 'Pimani mbewu yanu yoyamba!'
            : 'Scan your first crop!',
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

  Widget _buildHistoryCard(DiagnosisResult result, bool isChichewa) {
    final severityColor = _getSeverityColor(result.severity);
    final confidencePercent = (result.confidence * 100).round();
    final confidenceLabel = isChichewa
        ? '$confidencePercent% chikumbutso'
        : '$confidencePercent% confidence';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.cropType.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.diagnosisName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    confidenceLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildSeverityBadge(
                      result.severity,
                      severityColor,
                      isChichewa,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgoFromTimestamp(result.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(Severity severity, Color color, bool isChichewa) {
    final label = _severityLabel(severity, isChichewa);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _severityLabel(Severity severity, bool isChichewa) {
    switch (severity) {
      case Severity.low:
        return isChichewa ? 'yotsika' : 'Low';
      case Severity.medium:
        return isChichewa ? 'Pakati' : 'Medium';
      case Severity.high:
        return isChichewa ? 'Wakwera' : 'High';
    }
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return AppTheme.healthyGreen;
      case Severity.medium:
        return AppTheme.warningAmber;
      case Severity.high:
        return AppTheme.diseaseRed;
    }
  }
}
