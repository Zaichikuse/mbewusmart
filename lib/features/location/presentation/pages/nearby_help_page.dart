import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/location_bloc.dart';
import '../../../location/domain/entities/extension_officer.dart';
import '../../../location/domain/entities/agro_dealer.dart';
import '../../../location/data/datasources/malawi_data_source.dart';

class NearbyHelpPage extends StatefulWidget {
  const NearbyHelpPage({super.key});

  @override
  State<NearbyHelpPage> createState() => _NearbyHelpPageState();
}

class _NearbyHelpPageState extends State<NearbyHelpPage> {
  Timer? _timeoutTimer;
  bool _showFallback = false;

  // Blantyre coordinates as fallback so demo never gets stuck
  static const double _fallbackLat = -15.7861;
  static const double _fallbackLng = 35.0058;
  static const String _fallbackPlace = 'Blantyre';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Always trigger a fresh location request when this page opens
      context.read<LocationBloc>().add(LocationGetCurrent());

      // After 8 seconds, if still loading, show fallback (Blantyre) data
      // so the user is never stuck on a spinner.
      _timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!mounted) return;
        final state = context.read<LocationBloc>().state;
        if (state is! LocationLoaded) {
          setState(() => _showFallback = true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Thandizo Langa' : 'Nearby Help'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isChichewa),
            const SizedBox(height: 24),
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locationState) {
                // Use real GPS data if available
                if (locationState is LocationLoaded) {
                  return _buildHelpContent(
                    isChichewa: isChichewa,
                    lat: locationState.location.latitude,
                    lng: locationState.location.longitude,
                    placeLabel:
                        locationState.location.placeName ??
                        locationState.location.district ??
                        'Unknown',
                    isFallback: false,
                  );
                }

                // Use fallback (Blantyre) if timed out or errored
                if (_showFallback || locationState is LocationError) {
                  return _buildHelpContent(
                    isChichewa: isChichewa,
                    lat: _fallbackLat,
                    lng: _fallbackLng,
                    placeLabel: _fallbackPlace,
                    isFallback: true,
                  );
                }

                // Still loading
                return _buildLoadingCard(isChichewa);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isChichewa) {
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
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                isChichewa ? 'Othandizira Pafupi' : 'Help Near You',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isChichewa
                ? 'Funsani anthu amathandizo pafupi ndi inu'
                : 'Find extension officers and agro-dealers near you',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isChichewa) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            isChichewa ? 'Tikupezani malo anu...' : 'Finding your location...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() => _showFallback = true);
            },
            icon: const Icon(Icons.skip_next),
            label: Text(
              isChichewa
                  ? 'Pitirizani popanda location'
                  : 'Continue without location',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpContent({
    required bool isChichewa,
    required double lat,
    required double lng,
    required String placeLabel,
    required bool isFallback,
  }) {
    final officers = _sortedOfficers(lat, lng);
    final dealers = _sortedDealers(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location summary
        Row(
          children: [
            Icon(
              isFallback ? Icons.info_outline : Icons.place,
              color: isFallback ? AppTheme.warningAmber : AppTheme.primaryGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isFallback
                    ? (isChichewa
                          ? 'Tikukusonyezani athandizi a $placeLabel'
                          : 'Showing help in $placeLabel area')
                    : (isChichewa
                          ? 'Malo anu: $placeLabel'
                          : 'Your location: $placeLabel'),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _showFallback = false);
                context.read<LocationBloc>().add(LocationGetCurrent());
                _timeoutTimer?.cancel();
                _timeoutTimer = Timer(const Duration(seconds: 8), () {
                  if (!mounted) return;
                  final state = context.read<LocationBloc>().state;
                  if (state is! LocationLoaded) {
                    setState(() => _showFallback = true);
                  }
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isChichewa ? 'Sinthani' : 'Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Extension Officers section
        Row(
          children: [
            Icon(Icons.support_agent, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              isChichewa ? 'Ma Extension Officers' : 'Extension Officers',
              style: AppTextStyles.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (officers.isEmpty)
          _buildEmptyMessage(
            isChichewa
                ? 'Palibe Extension Officer wapezeka pafupi.'
                : 'No Extension Officers found nearby.',
          )
        else
          ...officers
              .take(5)
              .map(
                (officer) => _buildOfficerCard(
                  context,
                  officer,
                  isChichewa,
                  distanceKm: _distanceKm(
                    lat,
                    lng,
                    officer.latitude,
                    officer.longitude,
                  ),
                ),
              ),

        const SizedBox(height: 24),

        // Agro Dealers section
        Row(
          children: [
            Icon(Icons.store, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text(
              isChichewa ? 'Ma Agro-Dealers' : 'Agro-Dealers',
              style: AppTextStyles.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (dealers.isEmpty)
          _buildEmptyMessage(
            isChichewa
                ? 'Palibe Agro Dealer wapezeka pafupi.'
                : 'No Agro Dealers found nearby.',
          )
        else
          ...dealers
              .take(5)
              .map(
                (dealer) => _buildDealerCard(
                  context,
                  dealer,
                  isChichewa,
                  distanceKm: _distanceKm(
                    lat,
                    lng,
                    dealer.latitude,
                    dealer.longitude,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ExtensionOfficer> _sortedOfficers(double lat, double lng) {
    final officers = List<ExtensionOfficer>.from(
      MalawiDataSource.extensionOfficers,
    );
    officers.sort(
      (a, b) => _distanceKm(
        lat,
        lng,
        a.latitude,
        a.longitude,
      ).compareTo(_distanceKm(lat, lng, b.latitude, b.longitude)),
    );
    return officers;
  }

  List<AgroDealer> _sortedDealers(double lat, double lng) {
    final dealers = List<AgroDealer>.from(MalawiDataSource.agroDealers);
    dealers.sort(
      (a, b) => _distanceKm(
        lat,
        lng,
        a.latitude,
        a.longitude,
      ).compareTo(_distanceKm(lat, lng, b.latitude, b.longitude)),
    );
    return dealers;
  }

  Widget _buildOfficerCard(
    BuildContext context,
    ExtensionOfficer officer,
    bool isChichewa, {
    required double distanceKm,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        officer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        officer.area ?? officer.district,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            officer.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(officer.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(isChichewa ? 'Lowa Fono' : 'Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(
                      latitude: officer.latitude,
                      longitude: officer.longitude,
                      label: officer.name,
                    ),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: Text(isChichewa ? 'Mapu' : 'Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealerCard(
    BuildContext context,
    AgroDealer dealer,
    bool isChichewa, {
    required double distanceKm,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppTheme.accentOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dealer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dealer.district}${dealer.area != null ? " • ${dealer.area}" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dealer.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (dealer.products.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dealer.products.take(3).join(', '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(dealer.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(isChichewa ? 'Lowa Fono' : 'Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(
                      latitude: dealer.latitude,
                      longitude: dealer.longitude,
                      label: dealer.name,
                    ),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: Text(isChichewa ? 'Mapu' : 'Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openDirections({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label);
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&query=$encodedLabel&travelmode=driving',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;
}
