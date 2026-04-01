import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../location/domain/entities/extension_officer.dart';
import '../../../location/domain/entities/agro_dealer.dart';
import '../../../location/data/datasources/malawi_data_source.dart';

class NearbyHelpPage extends StatelessWidget {
  const NearbyHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded 
        ? settingsState.languageCode == 'ny' 
        : true;

    final officers = MalawiDataSource.extensionOfficers;
    final dealers = MalawiDataSource.agroDealers;

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
                      const Icon(Icons.location_on, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        isChichewa 
                            ? 'Othandizira Pafupi'
                            : 'Help Near You',
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isChichewa ? 'Ma Extension Officers' : 'Extension Officers',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 12),
            ...officers.take(5).map((officer) => _buildOfficerCard(context, officer, isChichewa)),
            const SizedBox(height: 24),
            Text(
              isChichewa ? 'Ma Agro-Dealers' : 'Agro-Dealers',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 12),
            ...dealers.take(5).map((dealer) => _buildDealerCard(context, dealer, isChichewa)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerCard(BuildContext context, ExtensionOfficer officer, bool isChichewa) {
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
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
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
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealerCard(BuildContext context, AgroDealer dealer, bool isChichewa) {
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
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
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
                  if (dealer.products != null && dealer.products!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dealer.products!.take(3).join(', '),
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
                    backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
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
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
