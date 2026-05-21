import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

class HistoryPage extends StatefulWidget {
  final int initialTab;
  final DiagnosisResult? initialDiagnosis;

  const HistoryPage({super.key, this.initialTab = 0, this.initialDiagnosis});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AiAssistantService _assistantService;
  String _selectedMonth = 'all';

  @override
  void initState() {
    super.initState();
    final safeInitialTab = widget.initialTab.clamp(0, 1);
    _assistantService = di.sl<AiAssistantService>();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: safeInitialTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }

      final contextName = _tabController.index == 1 ? 'Reports' : 'History';
      _assistantService.setCurrentUiContext(contextName);
    });

    _assistantService.setCurrentUiContext(
      safeInitialTab == 1 ? 'Reports' : 'History',
    );
    // FIX: Pass null to load ALL local scans on this device.
    // Since this phone belongs to one farmer, all scans on it are theirs.
    // Filtering by userId was hiding scans where userId wasn't saved correctly.
    context.read<DiagnosisBloc>().add(
      const DiagnosisHistoryRequested(userId: null),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;
    const String? userId = null; // Show all local scans on this device

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Mbiri ndi Malipoti' : 'History and Reports'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: isChichewa ? 'Mbiri' : 'History'),
            Tab(text: isChichewa ? 'Malipoti' : 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(isChichewa, userId),
          _buildReportsTab(isChichewa),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isChichewa, String? userId) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is DiagnosisLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DiagnosisHistoryLoaded) {
          if (state.history.isEmpty) {
            return _buildEmptyState(isChichewa);
          }

          final filteredHistory = _filterHistory(state.history);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DiagnosisBloc>().add(
                const DiagnosisHistoryRequested(userId: null),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final result = filteredHistory[index];
                return _buildHistoryCard(result, isChichewa, userId);
              },
            ),
          );
        }

        if (state is DiagnosisError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<DiagnosisBloc>().add(
                      const DiagnosisHistoryRequested(userId: null),
                    );
                  },
                  child: Text(isChichewa ? 'Yeselaniso' : 'Retry'),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(isChichewa);
      },
    );
  }

  Widget _buildReportsTab(bool isChichewa) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is DiagnosisHistoryLoaded) {
          final history = state.history;
          final filteredHistory = _filterHistory(history);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthFilter(isChichewa),
                const SizedBox(height: 16),
                _buildSummaryCards(history, filteredHistory, isChichewa),
                const SizedBox(height: 24),
                _buildCropDistribution(filteredHistory, isChichewa),
                const SizedBox(height: 24),
                _buildSeverityDistribution(filteredHistory, isChichewa),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildMonthFilter(bool isChichewa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Sunga chaka' : 'Filter by Month',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip('all', isChichewa ? 'Onse' : 'All'),
            _buildFilterChip(
              DateTime.now().month.toString(),
              isChichewa ? 'Mweyi uno' : 'This Month',
            ),
            _buildFilterChip(
              ((DateTime.now().month - 1) % 12 + 12) % 12 == 0
                  ? '12'
                  : ((DateTime.now().month - 1) % 12 + 12).toString(),
              isChichewa ? 'Mweyi yapita' : 'Last Month',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String month, String label) {
    final isSelected = _selectedMonth == month;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMonth = month;
        });
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }

  List<DiagnosisResult> _filterHistory(List<DiagnosisResult> history) {
    if (_selectedMonth == 'all') return history;

    final month = int.tryParse(_selectedMonth) ?? 0;
    return history.where((r) => r.timestamp.month == month).toList();
  }

  Widget _buildSummaryCards(
    List<DiagnosisResult> allHistory,
    List<DiagnosisResult> filteredHistory,
    bool isChichewa,
  ) {
    final count = filteredHistory.length;
    final diseaseCount = filteredHistory
        .where((r) => r.type.name == 'disease')
        .length;
    final pestCount = filteredHistory
        .where((r) => r.type.name == 'pest')
        .length;
    final healthyCount = filteredHistory
        .where((r) => r.type.name == 'healthy')
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                isChichewa ? 'Onse' : 'Total',
                count.toString(),
                Icons.summarize,
                AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                isChichewa ? 'Matenda' : 'Diseases',
                diseaseCount.toString(),
                Icons.coronavirus,
                AppTheme.diseaseRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                isChichewa ? 'Zotchinga' : 'Pests',
                pestCount.toString(),
                Icons.bug_report,
                AppTheme.pestOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                isChichewa ? 'Zabwino' : 'Healthy',
                healthyCount.toString(),
                Icons.check_circle,
                AppTheme.healthyGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropDistribution(
    List<DiagnosisResult> history,
    bool isChichewa,
  ) {
    final maize = history.where((r) => r.type.name == 'maize').length;
    final cassava = history.where((r) => r.type.name == 'cassava').length;
    final tomato = history.where((r) => r.type.name == 'tomato').length;
    final total = history.isEmpty ? 1 : history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Mianga ya Zipatso' : 'Crop Distribution',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDistributionRow('🌽 Maize', maize, total),
              const SizedBox(height: 8),
              _buildDistributionRow('🫘 Cassava', cassava, total),
              const SizedBox(height: 8),
              _buildDistributionRow('🍅 Tomato', tomato, total),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityDistribution(
    List<DiagnosisResult> history,
    bool isChichewa,
  ) {
    final low = history.where((r) => r.severity.name == 'low').length;
    final medium = history.where((r) => r.severity.name == 'medium').length;
    final high = history.where((r) => r.severity.name == 'high').length;
    final total = history.isEmpty ? 1 : history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Yambiri ya Vuto' : 'Severity Distribution',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDistributionRow('Low', low, total, AppTheme.healthyGreen),
              const SizedBox(height: 8),
              _buildDistributionRow(
                'Medium',
                medium,
                total,
                AppTheme.warningAmber,
              ),
              const SizedBox(height: 8),
              _buildDistributionRow('High', high, total, AppTheme.diseaseRed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionRow(
    String label,
    int count,
    int total, [
    Color? color,
  ]) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                color ?? AppTheme.primaryGreen,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percentage%',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isChichewa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            isChichewa ? 'Palibe mbiri' : 'No history yet',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isChichewa
                ? 'Zopima zanu zidzasungidwa apa'
                : 'Your diagnoses will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    DiagnosisResult result,
    bool isChichewa,
    String? userId,
  ) {
    final chatMessages = _assistantService.loadHistory(
      isChichewa ? 'ny' : 'en',
      userId: userId,
      diagnosisId: result.id,
    );
    final linkedMessages = chatMessages
        .where((m) => m.diagnosisId == result.id)
        .toList();
    final hasConversation = linkedMessages.isNotEmpty;
    final latestChat = hasConversation ? linkedMessages.last.text : null;

    return Pressable(
      onTap: () => _showDetailDialog(result, isChichewa),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getSeverityColor(
                    result.severity,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDiagnosisIcon(result.type.name),
                  color: _getSeverityColor(result.severity),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChichewa
                          ? result.diagnosisNameChichewa
                          : result.diagnosisName,
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(
                          isChichewa
                              ? result.type.displayNameChichewa
                              : result.type.displayName,
                          _getSeverityColor(result.severity),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(result.timestamp),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    if (hasConversation) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                latestChat!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${linkedMessages.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDetailDialog(DiagnosisResult result, bool isChichewa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
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

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                            result.severity,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getDiagnosisIcon(result.type.name),
                          color: _getSeverityColor(result.severity),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isChichewa
                                  ? result.diagnosisNameChichewa
                                  : result.diagnosisName,
                              style: AppTextStyles.headingMedium,
                            ),
                            Text(
                              '${(result.confidence * 100).toStringAsFixed(0)}% ${isChichewa ? 'chikumbutso' : 'confidence'}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildDetailRow(
                    isChichewa ? 'Mtundu' : 'Type',
                    isChichewa
                        ? result.type.displayNameChichewa
                        : result.type.displayName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Yambiri' : 'Severity',
                    isChichewa
                        ? result.severity.displayNameChichewa
                        : result.severity.displayName,
                  ),
                  _buildDetailRow(
                    isChichewa ? 'Tsiku' : 'Date',
                    _formatDate(result.timestamp),
                  ),

                  if (result.treatment != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      isChichewa ? 'Mankhwala' : 'Treatment',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(result.treatment!, style: AppTextStyles.bodyMedium),
                  ],

                  if (result.recommendation != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      isChichewa ? 'Ndondomeko' : 'Recommendation',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.recommendation!,
                      style: AppTextStyles.bodyMedium,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Color _getSeverityColor(dynamic severity) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
