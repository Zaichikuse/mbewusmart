import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../bloc/disease_watch_bloc.dart';
import '../widgets/disease_watch_card.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/disease_detail_bottom_sheet.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/routes/app_routes.dart';

class DiseaseWatchPage extends StatefulWidget {
  final String cropType;

  const DiseaseWatchPage({super.key, required this.cropType});

  @override
  State<DiseaseWatchPage> createState() => _DiseaseWatchPageState();
}

class _DiseaseWatchPageState extends State<DiseaseWatchPage> {
  late CropType _crop;
  DiagnosisCategory? _currentFilter;

  @override
  void initState() {
    super.initState();
    _crop = CropType.values.firstWhere(
      (c) => c.name == widget.cropType,
      orElse: () => CropType.maize,
    );

    // Load disease watch data on init
    context.read<DiseaseWatchBloc>().add(
      LoadDiseaseWatchRequested(widget.cropType),
    );
  }

  Future<void> _onRefresh() async {
    context.read<DiseaseWatchBloc>().add(
      RefreshDiseaseWatchRequested(widget.cropType),
    );
  }

  void _showDetailModal(DiseaseTrendCard trend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiseaseDetailBottomSheet(trend: trend),
    );
  }

  void _onScanNow() {
    // Navigate to scan with the current crop preselected
    context.go('${AppRoutes.scan}?crop=${widget.cropType}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Disease Watch — ${_crop.displayName}'),
            Text(
              'See what farmers across Malawi are reporting',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<DiseaseWatchBloc, DiseaseWatchState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Main content
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: CategoryFilterChips(
                        selectedCategory: _currentFilter,
                        onCategoryChanged: (category) {
                          setState(() => _currentFilter = category);
                          context.read<DiseaseWatchBloc>().add(
                            FilterByCategoryRequested(category),
                          );
                        },
                      ),
                    ),

                    // Monthly report banner
                    if (state is DiseaseWatchSuccess)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('📊', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${state.totalReportMonth} reports from farmers across Malawi this month',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Content
                    Expanded(child: _buildContent(state)),
                  ],
                ),
              ),

              // Sticky "Scan My Crop Now" button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child:
                      AppButton(
                            label: '📷 Scan My Crop Now',
                            onPressed: _onScanNow,
                            variant: AppButtonVariant.primary,
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scaleXY(
                            begin: 1.0,
                            end: 1.03,
                            duration: 1400.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(DiseaseWatchState state) {
    if (state is DiseaseWatchLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state is DiseaseWatchError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load disease reports',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<DiseaseWatchBloc>().add(
                    RefreshDiseaseWatchRequested(widget.cropType),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DiseaseWatchEmpty) {
      return Center(
        child: EmptyState(
          title: 'No reports yet',
          message: state.activeFilter != null
              ? 'No reports in this category — be the first to scan and help other farmers in your area.'
              : 'No reports yet — be the first to scan and help other farmers in your area.',
          icon: Icons.search_off,
        ),
      );
    }

    if (state is DiseaseWatchSuccess) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: state.trends.length,
        itemBuilder: (context, index) {
          final trend = state.trends[index];
          return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DiseaseWatchCard(
                  trend: trend,
                  onTap: () => _showDetailModal(trend),
                ),
              )
              .animate(delay: (index * 80).ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1);
        },
      );
    }

    return const SizedBox.expand();
  }
}
