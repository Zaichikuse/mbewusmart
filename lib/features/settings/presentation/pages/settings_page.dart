import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/settings_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded 
        ? settingsState.languageCode == 'ny' 
        : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Ma Settings' : 'Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final notificationsEnabled = state is SettingsLoaded 
              ? state.notificationsEnabled 
              : true;
          final languageCode = state is SettingsLoaded 
              ? state.languageCode 
              : 'ny';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(isChichewa ? 'General' : 'General'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildLanguageTile(context, languageCode, isChichewa),
                const Divider(height: 1),
                _buildNotificationTile(context, notificationsEnabled, isChichewa),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionTitle(isChichewa ? 'Account' : 'Account'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildTile(
                  icon: Icons.person_outline,
                  title: isChichewa ? 'Profile' : 'Profile',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: isChichewa ? 'Change PIN' : 'Change PIN',
                  onTap: () {},
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionTitle(isChichewa ? 'App' : 'App'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildTile(
                  icon: Icons.info_outline,
                  title: isChichewa ? 'About' : 'About',
                  onTap: () => _showAboutDialog(context, isChichewa),
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.help_outline,
                  title: isChichewa ? 'Help' : 'Help & Support',
                  onTap: () {},
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSettingsCard([
                _buildTile(
                  icon: Icons.logout,
                  title: isChichewa ? 'Tulukani' : 'Logout',
                  iconColor: AppTheme.errorRed,
                  textColor: AppTheme.errorRed,
                  onTap: () => _showLogoutDialog(context, isChichewa),
                ),
              ]),
              
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'MbewuSmart v1.0.0',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String currentLanguage, bool isChichewa) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(isChichewa ? 'Chilankhulo' : 'Language'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLanguage == 'ny' ? 'Chichewa' : 'English',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showLanguageDialog(context, currentLanguage, isChichewa),
    );
  }

  Widget _buildNotificationTile(BuildContext context, bool enabled, bool isChichewa) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined),
      title: Text(isChichewa ? 'Zizindikiro' : 'Notifications'),
      value: enabled,
      onChanged: (value) {
        context.read<SettingsBloc>().add(SettingsNotificationsToggled(value));
      },
      activeThumbColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLanguage, bool isChichewa) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChichewa ? 'Sankha Chilankhulo' : 'Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(SettingsLanguageChanged(value!));
                    Navigator.pop(dialogContext);
                  },
                ),
                onTap: () {
                  context.read<SettingsBloc>().add(const SettingsLanguageChanged('en'));
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: const Text('Chichewa'),
                leading: Radio<String>(
                  value: 'ny',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(SettingsLanguageChanged(value!));
                    Navigator.pop(dialogContext);
                  },
                ),
                onTap: () {
                  context.read<SettingsBloc>().add(const SettingsLanguageChanged('ny'));
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, bool isChichewa) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChichewa ? 'Mukufuna kutuluka?' : 'Logout?'),
          content: Text(
            isChichewa 
                ? 'Kodi mukuvomera kutuluka pa akaunti yanu?'
                : 'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Iai' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
              ),
              child: Text(isChichewa ? 'Tulukani' : 'Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context, bool isChichewa) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.eco, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text('MbewuSmart'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChichewa 
                    ? 'MbewuSmart ndi pulojekiti yothandizira omwe akugwira ntchito m\'dziko la Malawi kuti awerenge matenda azizolongo, zinthu zokhotera, ndi zosowa za zakudya.'
                    : 'MbewuSmart is a project to help farmers in Malawi detect crop diseases, pests, and nutrient deficiencies.',
              ),
              const SizedBox(height: 16),
              const Text('Version 1.0.0'),
              const SizedBox(height: 8),
              Text(
                isChichewa ? '© 2024 MbewuSmart' : '© 2024 MbewuSmart',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Uli' : 'OK'),
            ),
          ],
        );
      },
    );
  }
}
