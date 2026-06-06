import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/map_marker_model.dart';
import '../../manager/presentation/pages/manager_reports_page.dart';
import 'map_marker_widget.dart';

class CaseInfoBottomCard extends StatelessWidget {
  final MapMarker marker;
  final VoidCallback onClose;

  const CaseInfoBottomCard({
    super.key,
    required this.marker,
    required this.onClose,
  });

  static const Color _managerGreen = Color(0xFF2E5D2E);

  Color get _severityColor => MapMarkerWidget.dotColor(marker.severity);

  String get _severityLabel {
    switch (marker.severity.toLowerCase()) {
      case 'high':
        return 'HIGH SEVERITY';
      case 'medium':
        return 'MEDIUM SEVERITY';
      default:
        return 'LOW SEVERITY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('d MMMM yyyy').format(marker.dateReported);
    final regionText = marker.region.trim().isEmpty
        ? 'Unknown Region'
        : marker.region.trim();
    final districtText = marker.district.trim().isEmpty
        ? 'Unknown District'
        : marker.district.trim();
    final localityText = marker.locality.trim();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _severityColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _severityLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _severityColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            marker.diseaseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: _managerGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      regionText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      localityText.isEmpty
                          ? districtText
                          : '$districtText, $localityText',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, 'Reported by: ${marker.farmerName}'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, 'Date: $dateText'),
          const SizedBox(height: 6),
          _infoRow(Icons.eco_outlined, 'Crop: ${marker.cropAffected}'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManagerReportsPage(
                          initialDistrict: marker.district.trim().isEmpty
                              ? null
                              : marker.district.trim(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _managerGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Full Report'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _managerGreen,
                  side: const BorderSide(color: _managerGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _managerGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
          ),
        ),
      ],
    );
  }
}
