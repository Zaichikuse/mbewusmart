import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/pressable.dart';
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
      appBar: AppBar(title: Text(isChichewa ? 'Zosintha' : 'Settings')),
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
              _buildSectionTitle(isChichewa ? 'Zonse' : 'General'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildLanguageTile(context, languageCode, isChichewa),
                const Divider(height: 1),
                _buildNotificationTile(
                  context,
                  notificationsEnabled,
                  isChichewa,
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle(isChichewa ? 'Akaunti' : 'Account'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildTile(
                  icon: Icons.person_outline,
                  title: isChichewa ? 'Mbiri Yanu' : 'Profile',
                  onTap: () => _showProfileDialog(context, isChichewa),
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: isChichewa ? 'Sinthani PIN' : 'Change PIN',
                  onTap: () => _showChangePinDialog(context, isChichewa),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle(isChichewa ? 'Pulogalamu' : 'App'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _buildTile(
                  icon: Icons.info_outline,
                  title: isChichewa ? 'Za MbewuSmart' : 'About',
                  onTap: () => _showAboutDialog(context, isChichewa),
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.help_outline,
                  title: isChichewa ? 'Thandizo' : 'Help & Support',
                  onTap: () => _openHelpSupport(context, isChichewa),
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: isChichewa ? 'Chinsinsi Chathu' : 'Privacy Policy',
                  onTap: () => _openPrivacyPolicy(),
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
                child: Text('MbewuSmart v1.0.0', style: AppTextStyles.caption),
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

  Widget _buildLanguageTile(
    BuildContext context,
    String currentLanguage,
    bool isChichewa,
  ) {
    return Pressable(
      onTap: () => _showLanguageDialog(context, currentLanguage, isChichewa),
      child: ListTile(
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
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    bool enabled,
    bool isChichewa,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined),
      title: Text(isChichewa ? 'Mauthenga' : 'Notifications'),
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
    return Pressable(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // ============================================
  // CHANGE PIN — Now working
  // ============================================
  void _showChangePinDialog(BuildContext context, bool isChichewa) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(isChichewa ? 'Sinthani PIN' : 'Change PIN'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isChichewa
                      ? 'Lembani PIN yakale, kenako yatsopano.'
                      : 'Enter your current PIN, then a new one.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: isChichewa ? 'PIN Yakale' : 'Current PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 4) {
                      return isChichewa
                          ? 'PIN iyenera kukhala manambala 4'
                          : 'PIN must be 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: isChichewa ? 'PIN Yatsopano' : 'New PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 4) {
                      return isChichewa
                          ? 'PIN iyenera kukhala manambala 4'
                          : 'PIN must be 4 digits';
                    }
                    if (value == currentPinController.text) {
                      return isChichewa
                          ? 'PIN yatsopano iyenera kukhala yosiyana ndi yakale'
                          : 'New PIN must be different';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: isChichewa ? 'Tsimikizani PIN' : 'Confirm PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != newPinController.text) {
                      return isChichewa
                          ? 'PIN siyikufanana'
                          : 'PINs do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Lekani' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final currentUser = authBloc.state.user;
                if (currentUser == null) return;

                // NOTE: Do NOT compare currentUser.pin to the plaintext input here.
                // currentUser.pin is a bcrypt hash — plaintext will never equal it.
                // The bloc's _onChangePinRequested calls verifyPin() with bcrypt.checkpw.
                debugPrint(
                  '[ChangePIN] Dispatching with phone="${currentUser.phoneNumber}" '
                  'currentPin="${currentPinController.text}" '
                  'storedHashPrefix="${currentUser.pin?.substring(0, 7) ?? "null"}"',
                );

                Navigator.pop(dialogContext);

                authBloc.add(
                  AuthChangePinRequested(
                    currentPin: currentPinController.text,
                    newPin: newPinController.text,
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isChichewa
                          ? 'PIN yasinthidwa '
                          : 'PIN changed successfully',
                    ),
                    backgroundColor: AppTheme.healthyGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isChichewa ? 'Sungani' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // PROFILE — Quick info dialog
  // ============================================
  void _showProfileDialog(BuildContext context, bool isChichewa) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(isChichewa ? 'Mbiri Yanu' : 'Your Profile'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileRow(
                Icons.person_outline,
                isChichewa ? 'Dzina' : 'Name',
                user?.fullName ?? '-',
              ),
              const SizedBox(height: 8),
              _profileRow(
                Icons.phone_outlined,
                isChichewa ? 'Foni' : 'Phone',
                user?.phoneNumber ?? '-',
              ),
              const SizedBox(height: 8),
              _profileRow(
                Icons.location_on_outlined,
                isChichewa ? 'Dera' : 'District',
                user?.district ?? '-',
              ),
              const SizedBox(height: 8),
              _profileRow(
                Icons.badge_outlined,
                isChichewa ? 'Udindo' : 'Role',
                user?.role.name ?? '-',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Tsekani' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  // ============================================
  // PRIVACY POLICY — Opens in external browser
  // ============================================
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://zaichikuse.github.io/mbewusmart/PRIVACY_POLICY',
    );
    debugPrint('[PrivacyPolicy] Attempting to launch: $uri');
    try {
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('[PrivacyPolicy] canLaunchUrl returned: $canLaunch');
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('[PrivacyPolicy] launchUrl called successfully');
      } else {
        // Fallback: try without the canLaunchUrl gate (handles missing <queries> on older builds)
        debugPrint('[PrivacyPolicy] canLaunchUrl=false, trying launchUrl directly');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[PrivacyPolicy] ERROR launching URL: $e');
    }
  }

  // ============================================
  // HELP & SUPPORT — Now opens a real page
  // ============================================
  void _openHelpSupport(BuildContext context, bool isChichewa) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HelpSupportPage(isChichewa: isChichewa),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    String currentLanguage,
    bool isChichewa,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChichewa ? 'Sankhani Chilankhulo' : 'Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SettingsLanguageChanged(value!),
                    );
                    Navigator.pop(dialogContext);
                  },
                ),
                onTap: () {
                  context.read<SettingsBloc>().add(
                    const SettingsLanguageChanged('en'),
                  );
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: const Text('Chichewa'),
                leading: Radio<String>(
                  value: 'ny',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SettingsLanguageChanged(value!),
                    );
                    Navigator.pop(dialogContext);
                  },
                ),
                onTap: () {
                  context.read<SettingsBloc>().add(
                    const SettingsLanguageChanged('ny'),
                  );
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
                ? 'Mukufuna kutuluka pa akaunti yanu?'
                : 'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Ayi' : 'Cancel'),
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
                    ? 'MbewuSmart ndi pulogalamu yothandiza alimi a ku Malawi kuti azindikire matenda a mbewu, tizilombo, ndi zofuna za mbewu pogwiritsa ntchito AI.'
                    : 'MbewuSmart is an app that helps Malawian farmers identify crop diseases, pests, and nutrient deficiencies using AI.',
              ),
              const SizedBox(height: 16),
              _aboutRow(
                isChichewa ? 'Mtundu' : 'Version',
                '1.0.0',
              ),
              _aboutRow(
                isChichewa ? 'Kusinthidwa' : 'Build',
                '1',
              ),
              _aboutRow(
                isChichewa ? 'Wopanga' : 'Developer',
                'Zai Chikuse',
              ),
              _aboutRow(
                isChichewa ? 'Chaka' : 'Year',
                '2026',
              ),
              _aboutRow(
                isChichewa ? 'Teknoloji' : 'Tech',
                'Flutter • Firestore • Gemini AI',
              ),
              const SizedBox(height: 12),
              Text(
                isChichewa
                    ? 'Yapangidwa ndi chikondi kwa alimi a ku Malawi'
                    : 'Built with care for Malawian farmers',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryGreen,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Chabwino' : 'OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

// ============================================
// HELP & SUPPORT PAGE
// ============================================
class _HelpSupportPage extends StatelessWidget {
  final bool isChichewa;

  const _HelpSupportPage({required this.isChichewa});

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(String number) async {
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _email(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: Text(isChichewa ? 'Thandizo' : 'Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  isChichewa ? 'Tikuthandizani' : 'We are here to help',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isChichewa
                      ? 'Pezani mayankho a mafunso anu apa.'
                      : 'Find answers to your questions here.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact section
          Text(
            isChichewa ? 'Lumikizanani Nafe' : 'Contact Us',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),

          _contactCard(
            icon: Icons.phone,
            iconColor: AppTheme.primaryGreen,
            title: isChichewa ? 'Imbani Foni' : 'Call Support',
            subtitle: '+265 999 123 456',
            onTap: () => _call('+265999123456'),
          ),
          const SizedBox(height: 8),
          _contactCard(
            icon: Icons.chat,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: '+265 999 123 456',
            onTap: () => _whatsApp('265999123456'),
          ),
          const SizedBox(height: 8),
          _contactCard(
            icon: Icons.email,
            iconColor: AppTheme.accentOrange,
            title: 'Email',
            subtitle: 'support@mbewusmart.mw',
            onTap: () => _email('support@mbewusmart.mw'),
          ),

          const SizedBox(height: 24),

          // FAQs section
          Text(
            isChichewa
                ? 'Mafunso Ofunsidwa Kawiri-Kawiri'
                : 'Frequently Asked Questions',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),

          _faqTile(
            question: isChichewa
                ? 'Kodi ndi bwanji kufufuza mbewu?'
                : 'How do I scan a crop?',
            answer: isChichewa
                ? 'Tsegulani app, dinani "Fufuza Mbewu", sankhani mbewu yanu, ndipo jambulani chithunzi cha tsamba kapena chomera. AI idzakuuzani matenda kapena zovuta.'
                : 'Open the app, tap "Scan Crop", select your crop type, and take a clear photo of the leaf or plant. The AI will tell you if there is any disease or problem.',
          ),
          _faqTile(
            question: isChichewa
                ? 'Kodi ndingachite chiyani ngati zotsatira sizikutsimikiza?'
                : 'What do I do if results are uncertain?',
            answer: isChichewa
                ? 'Jambulani chithunzi china chowunika bwino. Ngati likadali lovuta, lankhulani ndi Afesa Officer wapafupi mu Nearby Help.'
                : 'Try taking another clearer photo with good lighting. If still uncertain, contact a nearby Extension Officer through the Nearby Help section.',
          ),
          _faqTile(
            question: isChichewa
                ? 'Kodi internet ndi yofunika?'
                : 'Do I need internet to use the app?',
            answer: isChichewa
                ? 'Inde, mukufuna internet pofufuza mbewu chifukwa AI imagwiritsa ntchito intaneti. Koma mbiri yanu imasungidwa pa phone yanu.'
                : 'Yes, you need internet when scanning because the AI works online. But your scan history is saved on your phone for offline viewing.',
          ),
          _faqTile(
            question: isChichewa
                ? 'Kodi zotsatira zanga zimaonedwa ndi ndani?'
                : 'Who sees my scan results?',
            answer: isChichewa
                ? 'Zotsatira zanu zimangokhala zanu pokhapokha mutapereka chilolezo cha kugawana ndi alimi ena pa Disease Watch. Dzina lanu silidziwidwa.'
                : 'Your results stay private unless you opt to share them on Disease Watch. Even then, only your district is shown — your name remains private.',
          ),
          _faqTile(
            question: isChichewa
                ? 'Kodi pulogalamu ikuchitira chiyani?'
                : 'What is Disease Watch?',
            answer: isChichewa
                ? 'Disease Watch ndi malo ojambulira matenda omwe akukula m\'madera osiyanasiyana. Mukhoza kuona zomwe alimi ena akupeza ndi kuphunzira nazo.'
                : 'Disease Watch shows what diseases other farmers in Malawi are reporting. You can learn from their experiences and prepare for outbreaks in your area.',
          ),
          _faqTile(
            question: isChichewa
                ? 'Kodi ndingasinthe chinenero?'
                : 'How do I change the language?',
            answer: isChichewa
                ? 'Pitani ku Settings, dinani Language, ndi sankhani Chichewa kapena Chingerezi.'
                : 'Go to Settings, tap Language, and select English or Chichewa.',
          ),

          const SizedBox(height: 24),

          // Quick guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      isChichewa ? 'Malangizo' : 'Tips for Best Results',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tip(
                  isChichewa
                      ? 'Jambulani m\'mawa kapena masana kuti pakhale kuwala kokwanira.'
                      : 'Take photos in morning or daylight for good lighting.',
                ),
                _tip(
                  isChichewa
                      ? 'Yandikirani phone pafupi ndi tsamba kapena chomera.'
                      : 'Hold the phone close to the leaf or plant.',
                ),
                _tip(
                  isChichewa
                      ? 'Onetsetsani kuti chithunzi chili chowoneka bwino.'
                      : 'Make sure the photo is clear and in focus.',
                ),
                _tip(
                  isChichewa
                      ? 'Jambulani matsamba osiyanasiyana ngati pali zizindikiro zosiyana.'
                      : 'Photograph different leaves if symptoms vary.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _faqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        iconColor: AppTheme.primaryGreen,
        collapsedIconColor: AppTheme.primaryGreen,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
