import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../analytics/screens/interactive_map_screen.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/entities/diagnosis_report.dart';

class ManagerAnalyticsPage extends StatefulWidget {
  const ManagerAnalyticsPage({super.key});

  @override
  State<ManagerAnalyticsPage> createState() => _ManagerAnalyticsPageState();
}

class _ManagerAnalyticsPageState extends State<ManagerAnalyticsPage> {
  late final ReportService _reportService = di.sl<ReportService>();

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isChichewa ? 'Kafukufuku' : 'Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: isChichewa ? 'Tsitsani' : 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<List<DiagnosisReport>>(
        stream: _reportService.watchAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isChichewa
                          ? 'Zalephera kutsitsa data'
                          : 'Failed to load data',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final allReports = snapshot.data ?? const [];
          if (allReports.isEmpty) {
            return _buildEmptyState(isChichewa);
          }

          final now = DateTime.now();
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          final recentReports = allReports
              .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
              .toList();

          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          final weeklyReports = allReports
              .where((r) => r.timestamp.isAfter(sevenDaysAgo))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStrip(allReports, recentReports, isChichewa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    isChichewa ? 'Madera Owopsa' : 'Hotspot Warnings',
                    Icons.warning_amber,
                    AppTheme.diseaseRed,
                  ),
                  const SizedBox(height: 12),
                  _buildHotspotCards(weeklyReports, isChichewa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    isChichewa ? 'Mapu wa Lipoti' : 'Disease Reports Map',
                    Icons.map,
                    AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildMap(recentReports, isChichewa),
                  const SizedBox(height: 12),
                  _buildMapLegend(isChichewa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    isChichewa
                        ? 'Matenda Ofala mu Sabata'
                        : 'Top Diseases This Week',
                    Icons.bar_chart,
                    AppTheme.accentOrange,
                  ),
                  const SizedBox(height: 12),
                  _buildDiseasesBarChart(weeklyReports, isChichewa),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    isChichewa
                        ? 'Kufufuza mu Masiku 30'
                        : 'Scans Over Last 30 Days',
                    Icons.show_chart,
                    AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildScansLineChart(recentReports, isChichewa),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryStrip(
    List<DiagnosisReport> all,
    List<DiagnosisReport> recent,
    bool isChichewa,
  ) {
    final uniqueDistricts = all
        .map((r) => (r.district ?? '').trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .length;
    final uniqueFarmers = all.map((r) => r.farmerId).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _miniStat(
            isChichewa ? 'Sabata Lino' : 'Last 30d',
            recent.length.toString(),
            Icons.event_note,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            isChichewa ? 'Alimi' : 'Farmers',
            uniqueFarmers.toString(),
            Icons.people,
            AppTheme.accentOrange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            isChichewa ? 'Maboma' : 'Districts',
            uniqueDistricts.toString(),
            Icons.map,
            AppTheme.warningAmber,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headingSmall),
      ],
    );
  }

  Widget _buildHotspotCards(
    List<DiagnosisReport> weeklyReports,
    bool isChichewa,
  ) {
    final clusters = <String, _Cluster>{};
    for (final r in weeklyReports) {
      final district = (r.district ?? '').trim();
      if (district.isEmpty || district == 'Unknown') continue;
      final key = '$district|${r.diagnosisName}';
      final existing = clusters[key];
      if (existing != null) {
        existing.count++;
      } else {
        clusters[key] = _Cluster(
          district: district,
          diseaseName: r.diagnosisName,
          cropType: r.cropType,
          count: 1,
        );
      }
    }

    final hotspots = clusters.values.where((c) => c.count >= 3).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    if (hotspots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.healthyGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.healthyGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.healthyGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isChichewa
                    ? 'Palibe madera owopsa pano. Madera onse akuoneka bwino.'
                    : 'No active outbreaks. All districts appear stable.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: hotspots
          .take(5)
          .map((c) => _hotspotCard(c, isChichewa))
          .toList(),
    );
  }

  Widget _hotspotCard(_Cluster cluster, bool isChichewa) {
    final color = cluster.count >= 5
        ? AppTheme.diseaseRed
        : AppTheme.warningAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cluster.diseaseName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isChichewa
                      ? '${cluster.count} alimi a ${cluster.district} achitira lipoti vuto ili sabata yino.'
                      : '${cluster.count} farmers in ${cluster.district} reported this in the past 7 days.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isChichewa
                        ? 'Tumizani chenjezo'
                        : 'Recommend district alert',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<DiagnosisReport> reports, bool isChichewa) {
    final locatedReports = reports.where((r) {
      final lat = r.latitude;
      final lng = r.longitude;
      return lat != null &&
          lng != null &&
          !(lat == 0 && lng == 0);
    }).length;

    final previewMarkers = <Marker>[];
    for (final r in reports) {
      final lat = r.latitude;
      final lng = r.longitude;
      if (lat == null || lng == null) continue;
      if (lat == 0 && lng == 0) continue;

      final severity = r.confidence >= 0.85
          ? 'high'
          : r.confidence >= 0.70
          ? 'medium'
          : 'low';
      final color = severity == 'high'
          ? const Color(0xFFC62828)
          : severity == 'medium'
          ? const Color(0xFFE65100)
          : const Color(0xFF2E7D32);

      previewMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 14,
          height: 14,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InteractiveMapScreen()),
        );
      },
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-13.2543, 34.3015),
                  initialZoom: 6.5,
                  minZoom: 5.0,
                  maxZoom: 6.5,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mbewusmart.mbewu_smart',
                  ),
                  MarkerLayer(markers: previewMarkers),
                ],
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isChichewa
                        ? '📍 $locatedReports malipoti — Dinani kuti muone mapu wonse'
                        : '📍 $locatedReports cases — Tap to open interactive map',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.open_in_full,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
              if (previewMarkers.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isChichewa
                          ? 'Palibe lipoti ndi malo'
                          : 'No reports with location data yet',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapLegend(bool isChichewa) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendDot(
          const Color(0xFF2E7D32),
          isChichewa ? 'Zochepa' : 'Low',
        ),
        _legendDot(
          const Color(0xFFE65100),
          isChichewa ? 'Wapakatikati' : 'Medium',
        ),
        _legendDot(
          const Color(0xFFC62828),
          isChichewa ? 'Waukulu' : 'High',
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildDiseasesBarChart(
    List<DiagnosisReport> weeklyReports,
    bool isChichewa,
  ) {
    final diseaseCounts = <String, int>{};
    for (final r in weeklyReports) {
      diseaseCounts[r.diagnosisName] =
          (diseaseCounts[r.diagnosisName] ?? 0) + 1;
    }

    if (diseaseCounts.isEmpty) {
      return _emptyChartCard(
        isChichewa ? 'Palibe data sabata yino' : 'No data for this week',
      );
    }

    final sorted = diseaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxCount = top.first.value.toDouble();

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
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCount + 1,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppTheme.primaryGreen,
                getTooltipItem: (group, idx, rod, _) {
                  final name = top[group.x].key;
                  final count = top[group.x].value;
                  return BarTooltipItem(
                    '$name\n$count reports',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: math.max(1, (maxCount / 4).ceilToDouble()),
                  getTitlesWidget: (value, meta) {
                    if (value == value.toInt().toDouble()) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTextStyles.caption,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= top.length) return const SizedBox();
                    final name = top[idx].key;
                    final short = name.length > 10
                        ? '${name.substring(0, 8)}...'
                        : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Text(
                          short,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(top.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].value.toDouble(),
                    color: AppTheme.primaryGreen,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildScansLineChart(
    List<DiagnosisReport> recentReports,
    bool isChichewa,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final buckets = List<int>.filled(30, 0);
    for (final r in recentReports) {
      final reportDay = DateTime(
        r.timestamp.year,
        r.timestamp.month,
        r.timestamp.day,
      );
      final daysAgo = today.difference(reportDay).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        buckets[29 - daysAgo]++;
      }
    }

    final hasAnyData = buckets.any((b) => b > 0);
    if (!hasAnyData) {
      return _emptyChartCard(
        isChichewa ? 'Palibe data ya masiku 30' : 'No data for last 30 days',
      );
    }

    final maxVal = buckets.reduce(math.max).toDouble();

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
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 29,
            minY: 0,
            maxY: maxVal + 1,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppTheme.primaryGreen,
                getTooltipItems: (spots) {
                  return spots.map((s) {
                    final dayOffset = 29 - s.x.toInt();
                    final date = today.subtract(Duration(days: dayOffset));
                    return LineTooltipItem(
                      '${date.day}/${date.month}\n${s.y.toInt()} scans',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: math.max(1, (maxVal / 4).ceilToDouble()),
                  getTitlesWidget: (value, meta) {
                    if (value == value.toInt().toDouble()) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTextStyles.caption,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 7,
                  getTitlesWidget: (value, meta) {
                    final dayOffset = 29 - value.toInt();
                    final date = today.subtract(Duration(days: dayOffset));
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: AppTextStyles.caption,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  30,
                  (i) => FlSpot(i.toDouble(), buckets[i].toDouble()),
                ),
                isCurved: true,
                color: AppTheme.primaryGreen,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyChartCard(String message) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isChichewa) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 80, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              isChichewa ? 'Palibe data' : 'No data yet',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isChichewa
                  ? 'Alimi akafufuza mbewu zawo, kafukufuku adzaonekera apa.'
                  : 'When farmers start scanning their crops, analytics will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cluster {
  final String district;
  final String diseaseName;
  final String cropType;
  int count;

  _Cluster({
    required this.district,
    required this.diseaseName,
    required this.cropType,
    required this.count,
  });
}
