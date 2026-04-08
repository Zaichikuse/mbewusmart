import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/home/presentation/pages/main_navigation_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/location/presentation/pages/nearby_help_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import 'app_routes.dart';

class AppRouter {
  static const String _languageSetupCompletedKey = 'language_setup_completed';
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
  final authState = authBloc.state;

  final isAuth = authState.status == AuthStatus.authenticated;

  final isOnSplash = state.matchedLocation == AppRoutes.splash;
  final isOnWelcome = state.matchedLocation == AppRoutes.welcome;
  final isOnLogin = state.matchedLocation == AppRoutes.login;

  // Always allow splash
  if (isOnSplash) {
    return null;
  }

  final settingsBox = Hive.box(AppConstants.settingsBox);
  final hasCompletedLanguageSetup =
      settingsBox.get(_languageSetupCompletedKey, defaultValue: false) as bool;
  final unauthLanding = hasCompletedLanguageSetup
      ? AppRoutes.login
      : AppRoutes.welcome;

  // If NOT logged in → stay on welcome/login ONLY
  if (!isAuth) {
    if (isOnWelcome && hasCompletedLanguageSetup) {
      return AppRoutes.login;
    }

    if (!isOnWelcome && !isOnLogin) {
      return unauthLanding;
    }
    return null;
  }

  // If logged in → go to home
  if (isAuth && (isOnWelcome || isOnLogin)) {
    return AppRoutes.home;
  }

  return null;
},
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const MainNavigationPage(initialIndex: 1),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const MainNavigationPage(initialIndex: 2),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const MainNavigationPage(initialIndex: 3),
      ),
      GoRoute(
        path: AppRoutes.nearbyHelp,
        builder: (context, state) => const NearbyHelpPage(),
      ),
      GoRoute(
        path: AppRoutes.officerDashboard,
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: AppRoutes.managerDashboard,
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: AppRoutes.dealerDashboard,
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: AppRoutes.conversations,
        builder: (context, state) => const ConversationsPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
