import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/localization/fallback_material_localizations_delegate.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';
import 'features/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'features/disease_watch/presentation/bloc/disease_watch_bloc.dart';
import 'features/onboarding/data/onboarding_prefs.dart';
import 'shared/routes/app_router.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/services/pii_encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize dependencies FIRST so Hive boxes (encrypted) are open
  await di.initDependencies();
  await PiiEncryptionService.warmUp();

  // Now we can read auth state from encrypted Hive
  final seenOnboarding = await OnboardingPrefs.hasSeenOnboarding();
  final localUser = await di.sl<AuthLocalDataSource>().getCurrentUser();
  final loggedIn = localUser != null;

  final String initialRoute = !seenOnboarding
      ? '/onboarding'
      : (!loggedIn ? '/login' : '/home');

  runApp(MbewuSmartApp(initialRoute: initialRoute));
}

class MbewuSmartApp extends StatefulWidget {
  final String initialRoute;

  const MbewuSmartApp({super.key, required this.initialRoute});

  @override
  State<MbewuSmartApp> createState() => _MbewuSmartAppState();
}

class _MbewuSmartAppState extends State<MbewuSmartApp> {
  late final AuthBloc _authBloc;
  late final SettingsBloc _settingsBloc;
  late final DiagnosisBloc _diagnosisBloc;
  late final AlertsBloc _alertsBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>();
    _authBloc.add(AuthCheckRequested());
    _settingsBloc = di.sl<SettingsBloc>()..add(SettingsLoadRequested());
    _diagnosisBloc = di.sl<DiagnosisBloc>();
    _alertsBloc = di.sl<AlertsBloc>();
    _appRouter = AppRouter(
      authBloc: _authBloc,
      initialLocation: widget.initialRoute,
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _settingsBloc.close();
    _diagnosisBloc.close();
    _alertsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        BlocProvider<DiagnosisBloc>.value(value: _diagnosisBloc),
        BlocProvider<LocationBloc>(create: (_) => di.sl<LocationBloc>()),
        BlocProvider<AlertsBloc>.value(value: _alertsBloc),
        BlocProvider<ConnectivityBloc>(
          create: (_) => di.sl<ConnectivityBloc>()..add(ConnectivityStarted()),
        ),
        BlocProvider<DiseaseWatchBloc>(
          create: (_) => di.sl<DiseaseWatchBloc>(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          Locale locale;
          if (settingsState is SettingsLoaded) {
            if (settingsState.languageCode == 'ny') {
              locale = const Locale('ny', 'MW');
            } else {
              locale = const Locale('en');
            }
          } else {
            locale = const Locale('ny', 'MW');
          }

          return MaterialApp.router(
            title: 'MbewuSmart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ny', 'MW')],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale?.languageCode) {
                  return supported;
                }
              }
              return supportedLocales.first;
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
