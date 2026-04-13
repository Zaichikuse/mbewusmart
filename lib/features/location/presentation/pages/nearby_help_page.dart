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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<LocationBloc>();
      if (bloc.state is! LocationLoaded) {
        bloc.add(LocationGetCurrent());
      }
    });
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
            Container(
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
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
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
            ),
            const SizedBox(height: 24),
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locationState) {
                if (locationState is LocationLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (locationState is LocationError) {
                  return _buildLocationError(
                    context,
                    isChichewa,
                    locationState,
                  );
                }

                if (locationState is! LocationLoaded) {
                  return _buildRequestLocationCard(context, isChichewa);
                }

                final officers = _sortedOfficers(locationState);
                final dealers = _sortedDealers(locationState);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationSummary(locationState, isChichewa),
                    const SizedBox(height: 20),
                    Text(
                      isChichewa
                          ? 'Ma Extension Officers'
                          : 'Extension Officers',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    ...officers
                        .take(5)
                        .map(
                          (officer) => _buildOfficerCard(
                            context,
                            officer,
                            isChichewa,
                            distanceKm: _distanceKm(
                              locationState.location.latitude,
                              locationState.location.longitude,
                              officer.latitude,
                              officer.longitude,
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),
                    Text(
                      isChichewa ? 'Ma Agro-Dealers' : 'Agro-Dealers',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    ...dealers
                        .take(5)
                        .map(
                          (dealer) => _buildDealerCard(
                            context,
                            dealer,
                            isChichewa,
                            distanceKm: _distanceKm(
                              locationState.location.latitude,
                              locationState.location.longitude,
                              dealer.latitude,
                              dealer.longitude,
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestLocationCard(BuildContext context, bool isChichewa) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isChichewa
                  ? 'Tifunika location yanu kuti tikusonyezeni thandizo lapafupi.'
                  : 'We need your location to show nearby help.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<LocationBloc>().add(LocationGetCurrent()),
              icon: const Icon(Icons.my_location),
              label: Text(isChichewa ? 'Pezani malo anga' : 'Get my location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError(
    BuildContext context,
    bool isChichewa,
    LocationError state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isChichewa
                  ? 'Sitinapeze malo anu pano. Chonde yatsani GPS ndi ma permissions kenako yesaninso.'
                  : 'Could not get your location. Please enable GPS and location permissions, then try again.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(state.message, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<LocationBloc>().add(LocationGetCurrent()),
              icon: const Icon(Icons.refresh),
              label: Text(isChichewa ? 'Yesaninso' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSummary(LocationLoaded state, bool isChichewa) {
    final label =
        state.location.placeName ?? state.location.district ?? 'Unknown';
    return Row(
      children: [
        const Icon(Icons.place, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isChichewa ? 'Malo anu: $label' : 'Your location: $label',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              context.read<LocationBloc>().add(LocationGetCurrent()),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(isChichewa ? 'Sinthani' : 'Refresh'),
        ),
      ],
    );
  }

  List<ExtensionOfficer> _sortedOfficers(LocationLoaded state) {
    final officers = List<ExtensionOfficer>.from(
      MalawiDataSource.extensionOfficers,
    );
    officers.sort(
      (a, b) =>
          _distanceKm(
            state.location.latitude,
            state.location.longitude,
            a.latitude,
            a.longitude,
          ).compareTo(
            _distanceKm(
              state.location.latitude,
              state.location.longitude,
              b.latitude,
              b.longitude,
            ),
          ),
    );
    return officers;
  }

  List<AgroDealer> _sortedDealers(LocationLoaded state) {
    final dealers = List<AgroDealer>.from(MalawiDataSource.agroDealers);
    dealers.sort(
      (a, b) =>
          _distanceKm(
            state.location.latitude,
            state.location.longitude,
            a.latitude,
            a.longitude,
          ).compareTo(
            _distanceKm(
              state.location.latitude,
              state.location.longitude,
              b.latitude,
              b.longitude,
            ),
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  const SizedBox(height: 4),
                  Text(
                    officer.area ?? officer.district,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 14,
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
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _makePhoneCall(officer.phone),
                  icon: const Icon(Icons.call, color: AppTheme.primaryGreen),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _openDirections(
                    latitude: officer.latitude,
                    longitude: officer.longitude,
                    label: officer.name,
                  ),
                  icon: const Icon(
                    Icons.navigation,
                    color: AppTheme.primaryGreen,
                  ),
                  tooltip: isChichewa ? 'Tsegulani mapu' : 'Open directions',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  const SizedBox(height: 4),
                  Text(
                    dealer.district,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 14,
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
            Column(
              children: [
                IconButton(
                  onPressed: () => _makePhoneCall(dealer.phone),
                  icon: const Icon(Icons.call, color: AppTheme.accentOrange),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _openDirections(
                    latitude: dealer.latitude,
                    longitude: dealer.longitude,
                    label: dealer.name,
                  ),
                  icon: const Icon(
                    Icons.navigation,
                    color: AppTheme.accentOrange,
                  ),
                  tooltip: isChichewa ? 'Tsegulani mapu' : 'Open directions',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange.withValues(
                      alpha: 0.1,
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
