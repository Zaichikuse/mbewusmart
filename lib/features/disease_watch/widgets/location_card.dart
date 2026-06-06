import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class LocationCard extends StatelessWidget {
  final String? region;
  final String? district;
  final String? locality;

  const LocationCard({
    super.key,
    required this.region,
    required this.district,
    required this.locality,
  });

  String _locationText(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final regionText = region?.trim() ?? '';
    final districtText = district?.trim() ?? '';
    final localityText = locality?.trim() ?? '';

    if (regionText.isEmpty && districtText.isEmpty && localityText.isEmpty) {
      return appLoc?.translate('unknownLocation') ?? 'Unknown location';
    }
    if (regionText.isNotEmpty &&
        districtText.isNotEmpty &&
        localityText.isNotEmpty) {
      return '$regionText · $districtText, $localityText';
    }
    if (regionText.isNotEmpty && districtText.isNotEmpty) {
      return '$regionText · $districtText';
    }
    if (regionText.isNotEmpty) return regionText;
    if (districtText.isNotEmpty && localityText.isNotEmpty) {
      return '$districtText, $localityText';
    }
    if (districtText.isNotEmpty) return districtText;
    return localityText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E0CA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationText(context),
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
