import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/routes/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../onboarding/data/onboarding_prefs.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const String _languageSetupCompletedKey = 'language_setup_completed';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final authState = context.read<AuthBloc>().state;

      if (authState.status == AuthStatus.authenticated) {
        try {
          context.go(AppRoutes.home);
        } catch (e) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        // If user hasn't seen onboarding yet, show it (only for unauthenticated users)
        final hasSeenOnboarding = await OnboardingPrefs.hasSeenOnboarding();
        if (!hasSeenOnboarding) {
          try {
            context.go(AppRoutes.onboarding);
          } catch (e) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
          }
          return;
        }

        final settingsBox = Hive.box(AppConstants.settingsBox);
        final hasCompletedLanguageSetup =
            settingsBox.get(_languageSetupCompletedKey, defaultValue: false)
                as bool;

        final nextRoute = hasCompletedLanguageSetup
            ? AppRoutes.login
            : AppRoutes.welcome;

        try {
          context.go(nextRoute);
        } catch (e) {
          Navigator.of(context).pushReplacementNamed(nextRoute);
        }
      }
    } catch (e) {
      // Fallback navigation if bloc is not available
      try {
        context.go(AppRoutes.welcome);
      } catch (e) {
        // Last resort - do nothing
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String languageCode = 'ny';
    try {
      final settingsState = context.watch<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        languageCode = settingsState.languageCode;
      }
    } catch (e) {
      // Use default
    }

    final isChichewa = languageCode == 'ny';

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(scale: _scaleAnimation, child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/mbewusmart_logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'MbewuSmart',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isChichewa
                    ? 'Mau a Obulungi a Zipatso'
                    : 'Smart Crop Health Assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isChichewa ? 'Kukonda...' : 'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
