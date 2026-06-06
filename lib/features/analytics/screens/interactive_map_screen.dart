import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../models/map_marker_model.dart';
import '../../reports/data/services/report_service.dart';
import '../../reports/domain/entities/diagnosis_report.dart';
import '../widgets/case_info_bottom_card.dart';
import '../widgets/map_legend_card.dart';
import '../widgets/map_marker_widget.dart';
import '../widgets/zoom_controls_widget.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with TickerProviderStateMixin {
  static const Color _managerGreen = Color(0xFF2E5D2E);
  static const LatLng _malawiCenter = LatLng(-13.2543, 34.3015);
  static const double _initialZoom = 6.5;

  late final ReportService _reportService = di.sl<ReportService>();
  final MapController _mapController = MapController();
  AnimationController? _flyController;
  MapMarker? _selectedMarker;

  @override
  void dispose() {
    _flyController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<MapMarker> _toMarkers(List<DiagnosisReport> reports) {
    return reports
        .map(MapMarker.fromDiagnosisReport)
        .whereType<MapMarker>()
        .toList();
  }

  void _onMarkerTap(MapMarker marker) {
    setState(() => _selectedMarker = marker);
    _animatedMapMove(marker.position, 14.0);
  }

  void _closeInfoCard() {
    setState(() => _selectedMarker = null);
  }

  void _zoomBy(double delta) {
    final currentZoom = _mapController.camera.zoom;
    final nextZoom = (currentZoom + delta).clamp(5.0, 18.0);
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _flyController?.dispose();

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final animation = CurvedAnimation(
      parent: _flyController!,
      curve: Curves.fastOutSlowIn,
    );

    animation.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _flyController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _flyController?.dispose();
        _flyController = null;
      }
    });

    _flyController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Map — Malawi'),
        backgroundColor: _managerGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DiagnosisReport>>(
        stream: _reportService.watchAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _managerGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load map data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF757575)),
                ),
              ),
            );
          }

          final markers = _toMarkers(snapshot.data ?? const []);
          final flutterMarkers = markers
              .map(
                (marker) => Marker(
                  point: marker.position,
                  width: MapMarkerWidget.pulseSize(marker.severity),
                  height: MapMarkerWidget.pulseSize(marker.severity),
                  child: MapMarkerWidget(
                    severity: marker.severity,
                    onTap: () => _onMarkerTap(marker),
                  ),
                ),
              )
              .toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _malawiCenter,
                  initialZoom: _initialZoom,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mbewusmart.mbewu_smart',
                  ),
                  MarkerLayer(markers: flutterMarkers),
                ],
              ),
              if (markers.isEmpty)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text('No reports with location data yet'),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: _CaseCounterChip(count: markers.length),
              ),
              const Positioned(top: 12, right: 12, child: MapLegendCard()),
              Positioned(
                right: 12,
                bottom: _selectedMarker != null ? 300 : 120,
                child: ZoomControlsWidget(
                  onZoomIn: () => _zoomBy(1.0),
                  onZoomOut: () => _zoomBy(-1.0),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: _selectedMarker != null ? 0 : -400,
                left: 0,
                right: 0,
                child: _selectedMarker == null
                    ? const SizedBox.shrink()
                    : CaseInfoBottomCard(
                        marker: _selectedMarker!,
                        onClose: _closeInfoCard,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaseCounterChip extends StatelessWidget {
  final int count;

  const _CaseCounterChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '📍 $count Active Cases',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
    );
  }
}
