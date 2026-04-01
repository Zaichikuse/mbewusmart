import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/routes/app_routes.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String _selectedLanguage = 'ny';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    try {
      final settingsState = context.read<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        setState(() {
          _selectedLanguage = settingsState.languageCode;
        });
      }
    } catch (e) {
      // Ignore - use default language
    }
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
    });
  }

  void _continueToLogin() {
    try {
      context.read<SettingsBloc>().add(SettingsLanguageChanged(_selectedLanguage));
    } catch (e) {
      // Ignore if bloc is not available
    }
    
    // Use GoRouter for navigation
    try {
      context.go(AppRoutes.login);
    } catch (e) {
      // Fallback to Navigator if GoRouter fails
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChichewa = _selectedLanguage == 'ny';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  size: 80,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isChichewa ? 'Takulandirani!' : 'Welcome!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isChichewa
                    ? 'Sankhani chilankhulo chanu'
                    : 'Select your preferred language',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildLanguageOption(
                code: 'ny',
                name: 'Chichewa',
                nativeName: 'Chichewa',
                flag: '🇲🇼',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                code: 'en',
                name: 'English',
                nativeName: 'English',
                flag: '🇬🇧',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continueToLogin,
                  child: Text(
                    isChichewa ? 'Pitani' : 'Continue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isChichewa
                    ? 'Chitukuko cha Zipatso za Malawi'
                    : 'Malawi Crop Development',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String name,
    required String nativeName,
    required String flag,
  }) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () => _selectLanguage(code),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
